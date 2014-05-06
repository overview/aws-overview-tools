The `manage` program: turning Overview from code to a website.

This program runs on its own `m1.micro` instance on Amazon Web Services.
(That means you don't need to install anything other than an ssh client on your
computer to deploy Overview.)

# Recipes

* To deploy new code: `overview-manage deploy main@_tag_`
* To deploy new code to only one machine: `overview-manage deploy main@_tag_ production.web`
* To deploy new config: `overview-manage deploy config` (_@tag_ is optional: it defaults to `origin/master`)

Want more? Sorry, you'll have to read up on _concepts_....

# Concepts

Nouns:

* A **source** is a Git repository that contains code.
* A **version** is a version of the *source*, identified by a "tree-ish". (For instance: `origin/master`, `tag1`, `aec6a94` or `3fbd31873e7b220dcbe535e06099a1856051b935`.)
* A **source artifact** is a set of files representing a compiled *source* at a given *version*. (For instance: a zipfile.) It includes a checksum for verifying itself.
* An **environment** is one of **production** or **staging**. We test stuff on *staging*; our live site is on *production*.
* A **component** is, conceptually, a service. Theoretically, it _should_ come from multiple *source artifacts*. Right now, it comes from just one. (That's awkward: if one *source artifact* contains config files and another contains jar files, then you need two components to run the service. We're working on it.)
* A **machine** is an Amazon EC2 Instance. It runs in one *environment*, and it runs many *components*. We identify it by its private IP address, e.g., `10.x.x.x`.
* A **machine type** is a recipe: it specifies how to build a *machine* and which *components* run on it. We identify it as, say, `production.web`.
* A **component artifact** is a group of files on a *machine*, built from a *source artifact*. It can be run. (It includes a checksum for verifying itself.) For instance: jar files.

Verbs:

* You **build** a *source* to produce a *source artifact*. This is slow. (If it were quick, we wouldn't need the source artifacts in the first place: we'd build on the fly.)
* You **publish** a *source artifact* to a *component* to produce a *component artifact* on each *machine* running that component.
* You **install** a *component artifact* on each *machine* running that *component* to stop a previously-running *version* (if any) and start the new version instead. (This step causes user-facing downtime; it should last a few milliseconds, tops.)
* You can **start**, **stop** and **restart** a *component* on a *machine*.
* You **deploy** a *source* to *build* it, *publish* all its *components*  to all *machines* and *install* all the resulting *component artifacts*.
* You can **clean** to delete old *source artifacts* and all corresponding *component artifacts* on all *machines*. (By default, we'll keep a _few_ old artifacts around, in case we need to roll back quickly.)

Let's sum that up. Here's where things are stored:

| Bunch of files | Key properties | Where it is | What you can do with it |
| -------------- | -------------- | ----------- | ----------------------- |
| source | URL | the `manage` instance, `/opt/overview/manage/sources/SOURCE.git` (bare GitHub clone) | *build* at a given version |
| source artifact | version | the `manage` instance, `/opt/overview/manage/source-artifacts/SOURCE/VERSION/` | *prepare* to publish; *verify* |
| (manage) component artifact | component, version, environment | the `manage` instance, `/opt/overview/manage/component-artifacts/COMPONENT/VERSION/ENVIRONMENT` | *publish* to all relevant machines; *verify* |
| (machine) component artifact | component, version, environment | each *machine* with that *component*, `/opt/overview/manage/component-artifacts/COMPONENT/VERSION/ENVIRONMENT` (same exact files as on `manage`) | *install*; *verify* |
| installed component artifact | | each *machine* with that *component*, usually a symlink, `/opt/overview/COMPONENT` | *start*, *stop*, *restart* |

# Development

You need Ruby >= 1.9.2. (You get bonus points for using Ruby >= 2.0.0.)

    bundle install
    bundle exec guard
    # and then edit code
