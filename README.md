# Blog SPA

This is a Blog web app made as a Single Page Application with the frontend in [Elm](https://elm-lang.org/) ([elm-spa](https://www.elm-spa.dev/)) and the backend in Python (Django). It also includes Server-side rendering on top of the client-side rendering to improve SEO.

# Features

-   Only the owner(s) and assigned staff of the website itself actually post, so not like Medium
-   Posts are written/typed out in Markdown format
-   Responsive design
-   SEO features:
    -   OpenGraph meta tags
    -   Sitemap
    -   Server-side rendering on key pages (homepape, post page) before hydration with the SPA

# Planned Features

-   Commenting on posts
-   Pagination on both the homepage and search page
-   Uploading of pictures or other media when writing/typing a post
