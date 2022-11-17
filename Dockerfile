FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

USER root

ARG NB_USER="jovyan"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    git \
    ca-certificates \
    #fonts-liberation \
    locales \
    gcc pkg-config libfreetype6-dev libpng-dev g++ \
    pandoc \
    sudo \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

#RUN sed -i "s/^#force_color_prompt=yes/force_color_prompt=yes/" /etc/skel/.bashrc && \
#   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd

USER ${NB_USER}

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -f -b -p /opt/conda && rm -rf ~/miniconda.sh

#ENV CONDA_DIR /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda --version

# Python packages
RUN pip install \
    "colabfold[alphafold] @ git+https://github.com/sokrypton/ColabFold" \
    onnx==1.12.0 \
    onnx-tf==1.10.0 \
    tf2onnx==1.13.0 \
    skl2onnx==1.13 \
    scikit-image==0.19.3 \
    opencv-python==4.6.0.66 \
    nibabel==4.0.2 \
    onnxruntime==1.13.1 \
    bioblend==1.0.0 \
    galaxy-ie-helpers==0.2.5 \
    numba==0.56.4 \
    aquirdturtle_collapsible_headings==3.1.0

RUN pip install \
    jupyterlab-nvdashboard==0.7.0 \
    bokeh==2.4.0 \
    jupyter_server==1.15.0 \
    jupyterlab==3.3.4 \
    nbclassic==0.4.8 \
    jupyterlab-git==0.39.3 \
    jupytext==1.14.1 \
    jupyterlab-execute-time==2.3.0 \
    jupyterlab-kernelspy==3.1.0 \
    jupyterlab-system-monitor==0.8.0 \
    jupyterlab-topbar==0.6.1 \
    seaborn==0.12.1 \
    elyra==3.8.0 \
    voila==0.3.5 \
    bqplot==0.12.36

RUN pip install \
    tensorflow-gpu==2.7.0 \
    tensorflow_probability==0.15.0

RUN conda install -c conda-forge mamba
RUN mamba install -y -q -c conda-forge -c bioconda kalign2=2.04 hhsuite=3.3.0

RUN pip install jax==0.3.24 jaxlib==0.3.24 dm-haiku==0.0.7

USER root 

RUN mkdir -p /home/$NB_USER/.ipython/profile_default/startup/
RUN mkdir -p /import
RUN mkdir -p /home/$NB_USER/notebooks/
RUN mkdir -p /home/$NB_USER/usecases/
RUN mkdir -p /home/$NB_USER/elyra/
RUN mkdir -p /home/$NB_USER/data

#ADD ./startup.sh /startup.sh
#ADD ./get_notebook.py /get_notebook.py

COPY ./startup.sh /startup.sh
COPY ./get_notebook.py /get_notebook.py

COPY ./galaxy_script_job.py /home/$NB_USER/.ipython/profile_default/startup/00-load.py
COPY ./ipython-profile.py /home/$NB_USER/.ipython/profile_default/startup/01-load.py
COPY ./jupyter_notebook_config.py /home/$NB_USER/.jupyter/

#ADD ./*.ipynb /home/$NB_USER/

COPY ./*.ipynb /home/$NB_USER/

COPY ./notebooks/*.ipynb /home/$NB_USER/notebooks/
COPY ./usecases/*.ipynb /home/$NB_USER/usecases/
COPY ./elyra/*.* /home/$NB_USER/elyra/

COPY ./data/*.tsv /home/$NB_USER/data/

#################
#COPY ./startup.sh /startup.sh && \
#    ./get_notebook.py /get_notebook.py && \
#    ./galaxy_script_job.py /home/$NB_USER/.ipython/profile_default/startup/00-load.py && \
#    ./ipython-profile.py /home/$NB_USER/.ipython/profile_default/startup/01-load.py && \
#    ./jupyter_notebook_config.py /home/$NB_USER/.jupyter/ && \
#    ./*.ipynb /home/$NB_USER/ && \
#    ./notebooks/*.ipynb /home/$NB_USER/notebooks/ && \
#    ./usecases/*.ipynb /home/$NB_USER/usecases/ && \
#    ./elyra/*.* /home/$NB_USER/elyra/ && \
#    ./data/*.tsv /home/$NB_USER/data/

#################

# ENV variables to replace conf file
ENV DEBUG=false \
    GALAXY_WEB_PORT=10000 \
    NOTEBOOK_PASSWORD=none \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    API_KEY=none \
    HISTORY_ID=none \
    REMOTE_HOST=none \
    DISABLE_AUTH=true \
    GALAXY_URL=none

RUN chown -R $NB_USER:users /home/$NB_USER /import

USER ${NB_USER}

WORKDIR /import

CMD /startup.sh
