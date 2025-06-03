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


PROJECT_ROOT = find_relative_project_root()
NON_CRITICAL_INFRA_DIR = PROJECT_ROOT / "non-critical-infra"
MAILING_LISTS_NIX = NON_CRITICAL_INFRA_DIR / "modules/mailserver/mailing-lists.nix"
assert MAILING_LISTS_NIX.exists()


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

    secret_path = NON_CRITICAL_INFRA_DIR / f"secrets/{address_id}-email-address.umbriel"
    encrypt_to_file(email, secret_path, force)

    click.secho()
    click.secho("Now add `", nl=False)
    click.secho(
        secret_path.relative_to(MAILING_LISTS_NIX.parent, walk_up=True),
        fg="blue",
        nl=False,
    )
    click.secho("` to the relevant mailing list in '", nl=False)
    click.secho(MAILING_LISTS_NIX, fg="blue")


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

    secret_path = NON_CRITICAL_INFRA_DIR / f"secrets/{address_id}-email-login.umbriel"
    encrypt_to_file(hashed_password, secret_path, force)

    nix_code = dedent(
        f"""\
        "{address_id}@nixos.org" = {{
          forwardTo = [
            # Add emails here
          ];
          loginAccount = {{
            encryptedHashedPassword = ../../secrets/{address_id}-email-login.umbriel;
            storeEmail = false;  # Set to `true` if you want to store email in a mailbox accessible via IMAP.
          }};
        }};
        """
    )
    click.secho()
    click.secho("Now add this login account to ", nl=False)
    click.secho(MAILING_LISTS_NIX, fg="blue", nl=False)
    click.secho("'. Add or edit an entry that looks like this:")
    click.secho()
    click.secho(indent(nix_code, prefix=" " * 4), fg="blue")


if __name__ == "__main__":
    main()
