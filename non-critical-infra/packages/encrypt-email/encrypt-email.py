#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path
from textwrap import dedent, indent

import click


def find_project_root(start: Path) -> Path:
    # Can search for `flake.nix` because there are multiple in this project.
    root_indicator = start / ".git/config"
    if root_indicator.exists():
        return start

    return find_project_root(start.parent)


def find_relative_project_root() -> Path:
    return find_project_root(Path.cwd()).relative_to(Path.cwd(), walk_up=True)


def encrypt_to_file(plaintext: str, secret_path: Path, force: bool) -> None:
    if secret_path.exists():
        if not force:
            msg = f"Refusing to clobber existing {secret_path}. Use `--force` to override."
            raise click.ClickException(msg)
        click.secho(f"Clobbering existing {secret_path}", fg="yellow")

    cp = subprocess.run(
        [
            "sops",
            "--encrypt",
            "--filename-override",
            secret_path,
            "/dev/stdin",
        ],
        cwd=secret_path.parent,
        text=True,
        check=True,
        stdout=subprocess.PIPE,
        input=plaintext,
    )

    secret_path.write_text(cp.stdout)
    subprocess.run(
        ["git", "add", "--intent-to-add", "--force", "--", secret_path], check=True
    )

    click.secho(f"Successfully generated {secret_path}", fg="green")


def hash_password(plaintext: str) -> str:
    cp = subprocess.run(
        ["mkpasswd", "--stdin", "--method=bcrypt"],
        stdout=subprocess.PIPE,
        input=plaintext,
        text=True,
        check=True,
    )
    return cp.stdout


@click.group()
def main() -> None:
    pass


@main.command()
@click.argument("address_id")
@click.argument("email")
@click.option("--force/--no-force", "-f/ ", default=False)
def address(address_id: str, email: str, force: bool) -> None:
    """
    Encrypt an email address (or email addresses) for inclusion in a mailing list.

    Example:

        \bencrypt-email address some-token 'me@example.com,you@example.com'

    Then follow the instructions for what to do next.
    """
    # Feel free to make the regex less restrictive if you need to.
    id_re = re.compile("[A-Za-z0-9-]+")
    if not id_re.fullmatch(address_id):
        msg = f"Given ID: {address_id!r} is invalid. Must match regex: {id_re.pattern}"
        raise click.ClickException(msg)

    # Make sure we aren't being given a text file that happens to have a newline at the end.
    clean_email = email.strip()
    if clean_email != email:
        click.secho("Removed whitespace surrounding given email address", fg="yellow")
    email = clean_email

    project_root = find_relative_project_root()
    non_critical_infra_dir = project_root / "non-critical-infra"

    secret_path = non_critical_infra_dir / f"secrets/{address_id}-email-address.umbriel"
    encrypt_to_file(email, secret_path, force)

    default_nix = non_critical_infra_dir / "modules/mailserver/default.nix"
    assert default_nix.exists()

    click.secho()
    click.secho("Now add `", nl=False)
    click.secho(
        secret_path.relative_to(default_nix.parent, walk_up=True),
        fg="blue",
        nl=False,
    )
    click.secho("` to the relevant mailing list under '", nl=False)
    click.secho("### Mailing lists go here ###", fg="blue", nl=False)
    click.secho("' in ", nl=False)
    click.secho(default_nix, fg="blue")


@main.command()
@click.argument("address_id")
@click.option("--force/--no-force", "-f/ ", default=False)
def login(address_id: str, force: bool) -> None:
    """
    Encrypt a password to set up a login account for a mailing list. The password must be given via stdin.

    Example:

        \bencrypt-email login test-sender < file-with-password

    Then follow the instructions for what to do next.
    """
    # Make sure we aren't being given a text file that happens to have a newline at the end.
    password = sys.stdin.read()
    clean_password = password.strip()
    if clean_password != password:
        click.secho("Removed whitespace surrounding given password", fg="yellow")
    password = clean_password

    hashed_password = hash_password(password)

    project_root = find_relative_project_root()
    non_critical_infra_dir = project_root / "non-critical-infra"

    secret_path = non_critical_infra_dir / f"secrets/{address_id}-email-login.umbriel"
    encrypt_to_file(hashed_password, secret_path, force)

    default_nix = non_critical_infra_dir / "modules/mailserver/default.nix"
    assert default_nix.exists()

    nix_code = dedent(
        f"""\
        "{address_id}@nixos.org" = {{
          forwardTo = [
            # Add emails here
          ];
          loginAccount.encryptedHashedPassword = ../../secrets/test-sender-email-login.umbriel;
        }};
        """
    )
    click.secho()
    click.secho("Now add this login account to ", nl=False)
    click.secho(default_nix, fg="blue", nl=False)
    click.secho(". Search for '", nl=False)
    click.secho("### Mailing lists go here ###", fg="blue", nl=False)
    click.secho("'. Add or edit an entry that looks like this:")
    click.secho()
    click.secho(indent(nix_code, prefix=" " * 4), fg="blue")


if __name__ == "__main__":
    main()
