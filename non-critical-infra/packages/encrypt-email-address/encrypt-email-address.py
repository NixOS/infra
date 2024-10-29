#!/usr/bin/env python3

import re
import subprocess
from pathlib import Path

import click


def find_project_root(start: Path) -> Path:
    # Can search for `flake.nix` because there are multiple in this project.
    root_indicator = start / ".git/config"
    if root_indicator.exists():
        return start

    return find_project_root(start.parent)


@click.command()
@click.argument("address_id")
@click.argument("email")
@click.option("--force/--no-force", "-f/ ", default=False)
def main(address_id: str, email: str, force: bool) -> None:
    """
    Encrypt an email address (or email addresses) for inclusion in a mailing list.

    Example:

        \bencrypt-email-address some-token 'me@example.com,you@example.com'

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

    project_root = find_project_root(Path.cwd()).relative_to(Path.cwd(), walk_up=True)
    non_critical_infra_dir = project_root / "non-critical-infra"

    secret_path = non_critical_infra_dir / f"secrets/{address_id}-email.umbriel"

    if secret_path.exists():
        if not force:
            msg = f"Refusing to clobber existing {secret_path}. Use `--force` to override."
            raise click.ClickException(msg)
        click.secho(f"Clobbering existing {secret_path}", fg="yellow")

    sops_config = non_critical_infra_dir / ".sops.yaml"
    cp = subprocess.run(
        [
            "sops",
            "--encrypt",
            "--config",
            sops_config,
            "--filename-override",
            secret_path,
            "/dev/stdin",
        ],
        text=True,
        check=True,
        stdout=subprocess.PIPE,
        input=email,
    )

    secret_path.write_text(cp.stdout)
    subprocess.run(
        ["git", "add", "--intent-to-add", "--force", "--", secret_path], check=True
    )

    click.secho(f"Successfully generated {secret_path}", fg="green")

    mailing_list_nix = non_critical_infra_dir / "modules/mailserver/mailing-lists.nix"
    assert mailing_list_nix.exists()

    click.secho()
    click.secho("Now add yourself to ", nl=False)
    click.secho(mailing_list_nix, fg="blue", nl=False)
    click.secho(". ")

    click.secho()
    click.secho("Lastly, add `", nl=False)
    click.secho(
        secret_path.relative_to(mailing_list_nix.parent, walk_up=True),
        fg="blue",
        nl=False,
    )
    click.secho("` to the relevant mailing list under '", nl=False)
    click.secho("# Mailing lists go here.", fg="blue", nl=False)
    click.secho("'.")


if __name__ == "__main__":
    main()
