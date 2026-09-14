# Portfolio website

The static portfolio in [site/](site/index.html) presents the cloud operations
work in this repository.

## Content and local preview

- Overview: selected artifacts, AWS experience, credentials, and engineering approach.
- Library: links to the owner-provided [learning library repository](https://github.com/CloudSec-Jay/Cloud-Security-Learning-Library).
- Blog: a direct link to the owner-provided Medium profile; articles are not mirrored.
- Contact: labeled placeholder form and an active LinkedIn contact link.
- Roadmap: dependency-ordered work and expected validation evidence.

Edit the HTML and shared CSS directly. No JavaScript, application server, build
dependencies, tracking, or contact API is required. Google Fonts is the only
external asset service; system font fallbacks keep the site usable offline.
Navigation remains available at mobile widths and with JavaScript disabled.

From the repository root:

```bash
python3 scripts/validate_site.py
python3 -m http.server 8000 --bind 127.0.0.1 --directory docs/site
```

Open http://localhost:8000. Check all four pages at desktop and mobile widths.
Use Tab to verify focus indicators and the skip link. The validator checks
local links, fragment targets, repository artifact paths, and allowed public
asset types; it does not verify external HTTP availability or visual layout.

Keep the published folder limited to public HTML, CSS, and .nojekyll.
Add maintenance notes outside it. Update the asset allowlist deliberately if
adding images or other media. Keep project status aligned with component
READMEs. Never represent workflow source as proof of a successful run.

The library repository returned HTTP 404 to the available GitHub access during
this edit. Its URL is retained exactly as supplied by the owner; verify public
visibility before publication. No repository contents or article titles were inferred.

## Contact form

The form is intentionally disabled at the owner’s request to use placeholders.
No message is sent or stored. See [contact implementation review](contact-form-review.md)
for the assessment and activation requirements. Keep the CSP form-action restriction
until a real delivery endpoint is configured and tested.

## GitHub Pages

The [Pages workflow](../.github/workflows/deploy-pages.yml) validates pull
requests and publishes only `docs/site` after changes reach `main`.
Manual dispatch deploys only from `main`. Action commits are pinned to versions
resolved from the official action repositories.

The repository currently uses branch-based Pages from the root of `main`; switch
to GitHub Actions before using this workflow.

1. In repository Settings → Pages, select **GitHub Actions** as the source.
2. Merge the reviewed website changes to `main`.
3. Inspect the **Validate and deploy portfolio** workflow and its environment URL.

Expected URL after successful deployment:
https://cloudsec-jay.github.io/cloud-ops-engineering/

Publishing exposes all contents of `docs/site` publicly. The deployment job has
Pages write and OIDC permissions; pull-request validation has only contents read.
No AWS identities, infrastructure, or repository administration are managed.
The deployment follows the
[official static Pages workflow](https://github.com/actions/starter-workflows/blob/main/pages/static.yml).

Repository links target `main`, so new linked artifacts must be merged before
publication. Pages settings and a successful deployment must be verified in
GitHub; creating these files alone does not publish the website.

## Rollback and recovery

Revert the problematic site commit through a reviewed PR and merge to `main`.
That triggers validation and republishes the previous content. If the workflow
itself failed, restore its last working revision before dispatching from
`main`. To remove public access urgently, unpublish the site in repository
Settings → Pages. Site content is reproducible from Git; there is no database
or application state to restore.

## Profile content sources

Both AWS role descriptions and all nine certification names, issue dates, and
supplied expiration dates use the owner's latest pasted LinkedIn information.
The Microsoft credential ID is reproduced as supplied.
The Solutions Architect level was not specified, so none is inferred.
Credential cards link to the public LinkedIn profile; individual credential
verification URLs were not supplied. Dates are owner-provided, not independently
verified. No expiration is inferred where the source provides only an issue date.
