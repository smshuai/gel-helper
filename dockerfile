FROM rocker/tidyverse:3.6.3

RUN R -e "devtools::install_github('https://github.com/tf2/recipeB.git')"
