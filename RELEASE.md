# Release

Every major (X) and minor (Y) release should come with its own `release/vX.Y`
branch. For a major version bump, base it on the `master` branch; for a minor
version bump, base it on an existing `release/vX.Y` branch. For these cases,
create the new branch from the base branch with `git switch -c release/vX.Y`.
Patch (Z) releases should be done out of an existing major/minor branch.

For a major release, bump the version in `master` (remember a `-dev` suffix) and
the version in the new branch. For a minor release, only bump the version in the
new branch. For a patch release, bump the version in the existing branch. The
version must be bumped in these files:

* [`build.zig`](build.zig)
* [`build.zig.zon`](build.zig.zon)

Commit and push the version bumps and ensure that
[CI](https://github.com/vezel-dev/libap/actions) is green for the release
branch.

Next, run `git tag vX.Y.Z -m vX.Y.Z -s` to create and sign a release tag. Push
the tag and go to the
[releases page](https://github.com/vezel-dev/libap/releases) to create a release
from it, ideally with some well-written release notes. If something goes wrong,
you can run `git tag -d vX.Y.Z` and `git push origin :vX.Y.Z` to delete the tag
until you resolve the issue(s), and then repeat this step.
