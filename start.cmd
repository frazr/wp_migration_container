docker rm -f helpa
docker run -p80:80 -p222:22 -v helpavol:/data -v /c/Users/Emil/Documents/helpa:/data/sites/helpa/public_html --name helpa oas/helpav1