# Introduction

Thank you for considering contributing to OpenMapTiles. It's people like you that make OpenMapTiles such a great project. Talk to us at the OSM Slack **#openmaptiles** channel ([join](https://osmus-slack.herokuapp.com/)).

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

OpenMapTiles is an open source project and we love to receive contributions from our community — you! There are many ways to contribute, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests or writing code which can be incorporated into OpenMapTiles itself.

# Ground Rules

 * Create issues for any major changes and enhancements that you wish to make. Discuss things transparently and get community feedback.
 * Keep feature versions as small as possible, preferably one new feature per version.
 * Be welcoming to newcomers and encourage diverse new contributors from all backgrounds. See the [Python Community Code of Conduct](https://www.python.org/psf/codeofconduct/).

# Getting started

1. Create your own fork of the code
1. Do the changes in your fork
1. Create a pull request

# Code review process

We all make mistakes and bad coding decisions. So apart from the obvious fixes, all changes must be reviewed by another 2 members of the project. This also helps with the [bus factor](https://en.wikipedia.org/wiki/Bus_factor) -- there should always be other people in the team who know why a change was made.

For any non-trivial changes, all pull requests must be approved by at least three members of the OpenMapTiles team. Afterwards you can merge the PR if you have rights, or another person must do it for you.

Your pull request must:

 * Address a single issue or add a single item of functionality.
 * Contain a clean history of small, incremental, logically separate commits,
   with no merge commits.
 * Use clear commit messages.
 * Be possible to merge automatically.

When you modify rules of importing data in `mapping.yaml` or `*.sql`, please update also:

1. field description in `[layer].yaml`
2. comments starting with `#etldoc`
3. if needed, generate new `mapping_diagram.png` or `etl_diagram.png` using commands below:
```
make mapping-graph-[layer]
make etl-graph-[layer]
```
4. update layer description on https://openmaptiles.org/schema/ (https://github.com/openmaptiles/www.openmaptiles.org/tree/master/layers)
5. check if OMT styles are affected by the PR and if there is a need for style updates

When you are making PR that adds new spatial features to OpenMapTiles schema, please make also PR for at least one of our GL styles to show it on the map. Visual check is crucial.
