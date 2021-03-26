#!/bin/bash
#
# Deploys the current Spoon website to the website server.
# To test the site locally before deploying run `jekyll serve`
# in the website branch.
#
# Non-standard software required: ruby 2.4+, Jekyll 4.0+, xmlstarlet, jq, git, curl, Maven, JDK8+

set -o errexit
set -o nounset
set -o pipefail

function generate_website() {
    # Generate the website
    generate_javadoc

    cd "$WEBSITE_SOURCE_DIR"
    cp ../README.md doc_homepage.md

    LATESTVERSION=`curl -s "http://search.maven.org/solrsearch/select?q=g:%22fr.inria.gforge.spoon%22+AND+a:%22spoon-core%22&core=gav" | jq -r '.response.docs | map(select(.v | match("^[0-9.]+$")) | .v )| .[0]'`
    sed -i -e "s/^spoon_release: .*/spoon_release: $LATESTVERSION/" _config.yml
    SNAPSHOTVERSION=`xmlstarlet sel -t -v /_:project/_:version ../pom.xml`
    sed -i -e "s/^spoon_snapshot: .*/spoon_snapshot: \"$SNAPSHOTVERSION\"/" _config.yml
    jekyll build
}

function generate_javadoc() {
    # Generate Javadoc and place it in the website sources
    cd "$SOURCE_DIR"
    mvn -B site

    mkdir "$WEBSITE_SOURCE_DIR"/mvnsites/
    cp -r target/site/ "$WEBSITE_SOURCE_DIR"/mvnsites/spoon-core
}


function configure_git() {
    git config --local user.email "$GITHUB_USER"@users.noreply.github.com
    git config --local user.name "$GITHUB_USER"
}

function update_website() {
    # Update the existing website with the enwly generated one
    cd "$WEBSITE_DST_DIR"

    git init -b "$WEBSITE_BRANCH"
    configure_git

    git remote add origin "$WEBSITE_REPO_URL"
    git fetch origin

    # this is intricate; we update the HEAD reference without updating the working directory,
    # and then copy the website into the working directory and force-commit it
    git update-ref refs/heads/"$WEBSITE_BRANCH" refs/remotes/origin/"$WEBSITE_BRANCH"
    # must restore workflows
    git restore --staged .github/
    git restore .github/

    cp -r "$WEBSITE_GENERATED_DIR"/* .

    # clobber the README with a notice that the website is automatically generated
    echo '# Spoon website
This is the Spoon website hosted on GitHub pages. It is automatically generated
and deployed with a GitHub Actions workflow. See
[.github/workflows/deploy.yml](.github/workflows/deploy.yml).

> **Note:** The deploy workflow overwrites everything on the main branch
> _except_ for the [.github](.github) directory. Therefore, everything in the
> [.github](.github) directory is retained on automatic deployment, and you can
> edit its contents as usual, but files anywhere else are removed or overwritten.' > README.md


    git add . --force
    git commit -m "Update website" || {
        echo "Nothing to commit, website up-to-date"
        return
    }

    git push "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/$WEBSITE_REPO_SLUG" "$WEBSITE_BRANCH"
}

function deploy() {
    # Deploy the website
    cd "$INITIAL_WORKDIR"
    mkdir "$WEBSITE_DST_DIR"
    git clone "$SOURCE_REPO_URL" "$SOURCE_DIR"

    generate_website
    update_website
}

NUM_ARGS=3
if [[ "$#" -ne "$NUM_ARGS" ]]; then
    echo "usage: deploy_website.sh <workdir> <github_user> <github_token>"
    exit 1
fi

INITIAL_WORKDIR="$1"
GITHUB_USER="$2"
GITHUB_TOKEN="$3"

SOURCE_REPO_URL="https://github.com/INRIA/spoon.git"
SOURCE_DIR="$INITIAL_WORKDIR/temp-spoon-clone"
WEBSITE_SOURCE_DIR="$SOURCE_DIR/doc"
WEBSITE_GENERATED_DIR="$WEBSITE_SOURCE_DIR/_site"
WEBSITE_DST_DIR="$INITIAL_WORKDIR/spoon-website"
#WEBSITE_REPO_SLUG="SpoonLabs/spoonlabs.github.io" # TODO use
WEBSITE_REPO_SLUG="slarse/spoonlabs.github.io" # TODO remove
WEBSITE_REPO_URL="https://github.com/$WEBSITE_REPO_SLUG"
WEBSITE_BRANCH="main"

deploy
