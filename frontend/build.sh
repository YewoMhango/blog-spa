elm-spa build

rm -r "../app/static/"
mkdir "../app/static/"

cp -r ./public/dist/ ../app/static/dist/
mkdir ../app/static/css/
cp -r ./public/css/Besley/ ../app/static/css/Besley/
cp -r ./public/css/style.css ../app/static/css/style.css
cp -r ./public/favicon.ico ../app/static/favicon.ico
cp -r ./public/logo.svg ../app/static/logo.svg