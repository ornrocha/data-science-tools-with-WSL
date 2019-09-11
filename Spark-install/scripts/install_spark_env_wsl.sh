#!/bin/bash

SOURCES="$HOME/sources"
SPARKVERSION="spark-2.4.3"
SPARKHADOOP="$SPARKVERSION-bin-hadoop2.7"
SPARKURL="https://archive.apache.org/dist/spark/$SPARKVERSION/$SPARKHADOOP.tgz"
SCALAURL="https://downloads.lightbend.com/scala/2.11.12/scala-2.11.12.tgz"
CONDAENVNAME="env36"
PYTHONVERSION="3.6"


JUPYTERPORT="8000"
MAINDISK="c"
NOTEBOOKDIR="jupyter_notebooks"

NOTEBOOKSPATH="/mnt/$MAINDISK/$NOTEBOOKDIR"

cd_sources()
{
  if [ ! -d "$SOURCES" ]; then
     mkdir $SOURCES
     cd $SOURCES
  else
     cd $SOURCES
  fi
}

install_dependencies()
{
 sudo apt update
 sudo apt install openjdk-8-jdk-headless build-essential

 if [[ ! -d "$JAVA_HOME" ]]; then 
    echo 'export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"' >> $HOME/.bashrc
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
 fi

}

install_scala()
{
  cd_sources
  if [ ! -f "scala-2.11.12.tgz" ]; then
    wget $SCALAURL
  fi 
  
  tar -xvzf scala-2.11.12.tgz
  sudo mv scala-2.11.12 /opt/scala

   if [[ ! -d "$SCALA_HOME" ]]; then 
      echo 'export SCALA_HOME="/opt/scala"' >> $HOME/.bashrc
      export SCALA_HOME="/opt/scala"
   fi
}

install_spark()
{
  cd_sources
  if [ ! -f $SPARKHADOOP.tgz ]; then
    wget $SPARKURL
  fi  

  tar -xvzf $SPARKHADOOP.tgz
  sudo cp -R $SPARKHADOOP /opt/spark
  
  if [[ ! -d "$SPARK_HOME" ]]; then 
    echo 'export SPARK_HOME="/opt/spark"' >> $HOME/.bashrc
    export SPARK_HOME="/opt/spark"
  fi
}

install_miniconda()
{
  cd_sources
  wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
  chmod +x Miniconda3-latest-Linux-x86_64.sh
  bash Miniconda3-latest-Linux-x86_64.sh
  #echo 'export PATH="$PATH:$HOME/miniconda3/bin"' >> $HOME/.bashrc
  cd $HOME
  #exec bash
  echo "Creating conda environment" 
  $HOME/miniconda3/bin/conda create -n $CONDAENVNAME python=$PYTHONVERSION
  source $HOME/miniconda3/bin/activate $CONDAENVNAME
  conda install jupyter seaborn pandas 
}

reload_env_vars()
{
  echo 'export PATH="$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HOME/miniconda3/bin:$SCALA_HOME/bin:$SPARK_HOME/bin"' >> $HOME/.bashrc
  export PATH="$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$HOME/miniconda3/bin:$SCALA_HOME/bin:$SPARK_HOME/bin"
  source ~/.bashrc
}

install_spark_kernel()
{
  source $HOME/miniconda3/bin/activate $CONDAENVNAME

  pip install pixiedust
  jupyter pixiedust install
  pip install toree
  jupyter toree install --spark_home /opt/spark --kernel_name="Toree" --interpreters=Scala,SQL --user

  if [[ ! -d "$PYSPARK_PYTHON" ]]; then 
    echo 'export PYSPARK_PYTHON="'$HOME'/miniconda3/envs/'$CONDAENVNAME'/bin/python'$PYTHONVERSION'"' >> $HOME/.bashrc
    export PYSPARK_PYTHON="$HOME/miniconda3/envs/$CONDAENVNAME/bin/python$PYTHONVERSION"
  fi 

  if [[ ! -d "$PYLIB" ]]; then 
    echo 'export PYLIB="$SPARK_HOME:/python/lib"' >> $HOME/.bashrc
    export PYLIB="$SPARK_HOME:/python/lib"
  fi 

  if [[ ! -d "$PYSPARK_DRIVER_PYTHON" ]]; then 
    echo 'export PYSPARK_DRIVER_PYTHON="'$HOME'/miniconda3/envs/'$CONDAENVNAME'/bin/jupyter"' >> $HOME/.bashrc
    export PYSPARK_DRIVER_PYTHON="$HOME/miniconda3/envs/$CONDAENVNAME/bin/jupyter"
  fi   

  if [[ ! -d "$PYSPARK_DRIVER_PYTHON_OPTS" ]]; then 
    echo 'export PYSPARK_DRIVER_PYTHON_OPTS="notebook --NotebookApp.open_browser=False"' >> $HOME/.bashrc
    export PYSPARK_DRIVER_PYTHON_OPTS="notebook --NotebookApp.open_browser=False"
  fi

  if [[ ! -d "$PYTHONPATH" ]]; then
    cd $SPARK_HOME/python/lib
    PYJ="$(echo py4j*)" 
    echo 'export PYTHONPATH="$SPARK_HOME/python/lib/'$PYJ':$SPARK_HOME/python/lib/pyspark.zip:$PYTHONPATH"' >> $HOME/.bashrc
    export PYTHONPATH="$SPARK_HOME/python/lib/$PYJ:$SPARK_HOME/python/lib/pyspark.zip:$PYTHONPATH"
  fi

  cd $HOME
  #conda install -c conda-forge ipywidgets beakerx
}



add_start_script()
{
 cd $HOME
 touch init_jupyter_spark.sh

 mkdir $NOTEBOOKSPATH
 
 cat <<< "source $HOME/miniconda3/bin/activate $CONDAENVNAME
jupyter notebook --no-browser --ip='localhost' --notebook-dir='$NOTEBOOKSPATH' --port=$JUPYTERPORT" > init_jupyter_spark.sh

  
 chmod +x $HOME/init_jupyter_spark.sh
}



install_dependencies
install_scala
install_spark
install_miniconda
reload_env_vars
install_spark_kernel
add_start_script
