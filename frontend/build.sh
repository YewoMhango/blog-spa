elm-spa build

rm -r "../app/static/"
mkdir "../app/static/"

cp -r ./public/dist/ ../app/static/dist/
mkdir ../app/static/css/
cp -r ./public/css/Besley/ ../app/static/css/Besley/
cp -r "./public/css/IBM Plex Mono/" "../app/static/css/IBM Plex Mono/"
cp -r ./public/css/style.css ../app/static/css/style.css
cp -r ./public/css/style.css.map ../app/static/css/style.css.map
cp -r ./public/favicon.ico ../app/static/favicon.ico
cp -r ./public/logo.svg ../app/static/logo.svg
cp -r ./public/gmail.svg ../app/static/gmail.svg
cp -r ./public/github.svg ../app/static/github.svg
cp -r ./public/LinkedIn.svg ../app/static/LinkedIn.svg
cp -r ./public/web.svg ../app/static/web.svg