FROM smshuai/cnest:dev2

RUN apt-get update \
    && apt-get install -y \
       libopenmpi-dev \
       libzmq3-dev

RUN R -e "install.packages('foreach', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('doParallel', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('data.table', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('remotes', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "remotes::install_github('https://github.com/tf2/recipeB.git')"

RUN mkdir -p /scripts/
COPY scripts/* /scripts/
RUN chmod +x /scripts/*