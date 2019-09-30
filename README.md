# Tags and respective `Dockerfile` links

- [`3.7.0-alpine`, `3-alpine`, `alpine` *(3.7.0/alpine/Dockerfile)*](https://github.com/nbrownuk/docker-revealjs/blob/3.7.0/alpine/Dockerfile)
- [`3.7.0-onbuild`, `3-onbuild`, `onbuild` *(3.7.0/onbuild/Dockerfile)*](https://github.com/nbrownuk/docker-revealjs/blob/3.7.0/onbuild/Dockerfile)
- [`3.7.0`, `3`, `latest` *(3.7.0/Dockerfile)*](https://github.com/nbrownuk/docker-revealjs/blob/3.7.0/Dockerfile)

[![](https://images.microbadger.com/badges/image/nbrown/revealjs.svg)](https://microbadger.com/images/nbrown/revealjs "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/nbrown/revealjs.svg)](https://microbadger.com/images/nbrown/revealjs "Get your own version badge on microbadger.com")

# What is reveal.js?

[Reveal.js](https://github.com/hakimel/reveal.js) is a framework for creating [slick HTML-based presentations](https://github.com/hakimel/reveal.js/wiki/Example-Presentations). Based on Node.js, reveal.js provides a highly customisable presentation experience, with slides being authored in HTML and/or Markdown.

In addition to the choice of numerous themes shipped as standard with reveal.js, presentation behaviour and 'look and feel' can be further customised with [plugins](https://github.com/hakimel/reveal.js/wiki/Plugins,-Tools-and-Hardware) and runtime [configuration options](https://github.com/hakimel/reveal.js#configuration).

# How to use this image

## Encapsulating a presentation inside an image

Once a reveal.js presentation has been successfully authored, it can be encapsulated inside a Docker image. This makes it easy to store and share presentations - presentations can be pulled from a registry as a Docker image, with its content baked inside the image.

In order to encapsulate a presentation inside an image, use the `onbuild` variant. To build the image, create a `Dockerfile` with the single instruction:

```
FROM nbrown/revealjs:3.7.0-onbuild
```

and ensure the following are in the build context:

```
index.html    // the basis of the presentation
md/           // a directory containing a file with slides in markdown format, if required
media/        // a directory containing any media used in the presentation, if required
```

The media directory can contain video or image files for your presentation; just reference them relative to the current working directory; e.g.

```
<img src="media/UTS_Namespace.svg" alt="UTS Namespace" />
```

Additionally, the following directories are required in the build context for the inclusion of any customisations (see [https://github.com/hakimel/reveal.js#folder-structure](https://github.com/hakimel/reveal.js#folder-structure)):
```
css/
js/
plugin/
lib/
```

Not all presentations will require content in all of the directories above. However, because Docker doesn't currently have a [conditional `COPY` or `ADD` `Dockerfile` instruction](https://github.com/docker/docker/issues/13045), all of the above MUST exist in the build context, even if the directories are empty, otherwise the build will fail.

To build a Docker image encapsulating the presentation, and then run it; from the build context:

```
$ docker build -t my_presentation .
$ docker run -it --rm -p 8000:8000 my_presentation
```

Once a presentation is baked inside a Docker image, seemingly its configuration is fixed. The `onbuild` image, however, contains an entrypoint script which allows for runtime configuration. For example, to override the configuration of a presentation that normally requires the presenter stepping through the slides, so that it 'auto presents', use the following:

```
$ docker run -it --rm -p 8000:8000 my_presentation --loop=true --autoSlide=5000 --autoSlideStoppable=true
```

The entrypoint script updates the `index.html` file at runtime to reflect the chosen configuration. To find out what configuration options are available at runtime, run:

```
$ docker run --rm my_presentation --help
```

There are a large number of customisations available!

## Developing a presentation

Developing an HTML-based presentation with reveal.js is an iterative process, and its important to review changes as you progress. It is much easier to do this without having to build a new Docker image each time you make a change. For developing presentations, use the standard image version, and mount your presentation content from the host into the container.

If you run the standard image without any mounted content, you'll get the standard reveal.js demo presentation:

```
$ docker run -it --rm -p 8000:8000 nbrown/revealjs
```

If you have a presentation, with your content located in the current working directory, you might invoke the presentation using:

```
$ docker run -it --rm -p 8000:8000 -v $PWD/index.html:/reveal.js/index.html \
-v $PWD/media:/reveal.js/media -v $PWD/custom.css:/reveal.js/css/theme/custom.css \
-v $PWD/menu:/reveal.js/plugin/menu nbrown/revealjs
```

Changes that are made to the `index.html` file are watched for, and (provided the file is mounted RW) a server reload occurs when changes are saved. Hence, refreshing your browser will show the effects of any changes made to the `index.html` file, without a restart of the container.

This image can also be used to create themes for reveal.js. Themes are authored [using Sass](https://github.com/hakimel/reveal.js/blob/master/css/theme/README.md#creating-a-theme). Once you've defined your theme in Sass, it can be compiled into CSS using the standard image. Create an empty file in your presentation directory for the compiled Sass, mount this into your container along with the Sass source file, and issue the `grunt css-themes` command to compile it into CSS:

```
$ > custom.css
$ docker run -it --rm -v $PWD/custom.css:/reveal.js/css/themes/custom.css \
-v $PWD/custom.scss:/reveal.js/css/themes/source/custom.scss nbrown/revealjs \
grunt css-themes
```

The `custom.css` file will now contain your theme as CSS, and can be used in your presentation by mounting into your container at runtime.
