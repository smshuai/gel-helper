FROM rocker/r-base

RUN apt-get update \
    && apt-get install -y \
       libopenmpi-dev \
       libzmq3-dev

RUN install.r foreach iterators
RUN install.r doParallel doMC doRNG
RUN install.r data.table
RUN R -e "install.packages('remotes', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "remotes::install_github('https://github.com/tf2/recipeB.git')"

RUN mkdir -p /scripts/
COPY scripts/* /scripts/
RUN chmod +x /scripts/*