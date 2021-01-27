#!/bin/bash
#author		 :Orlando Rocha
#email       :ornrocha@gmail.com

SOURCES="$HOME/sources"

SPARKVERSION="3.0.1"
HADOOPVERSION="2.7"
PYTHONVERSION="3.9"

CONDAENVNAME="sparkenv"
JUPYTERSPARKKERNEL=0
JUPYTERINITSCRIPT=0


JUPYTERPORT="8000"
MAINDISK="c"
NOTEBOOKDIR="jupyter_notebooks"

NOTEBOOKSPATH=""


cd_sources()
{
  if [ ! -d "$SOURCES" ]; then
     mkdir $SOURCES
     cd $SOURCES
  else
     cd $SOURCES
  fi
}


init_setup()
{

if [ "$SPARKVERSION" = "2.4.5" ] || [ "$SPARKVERSION" = "2.4.6" ] || [ "$SPARKVERSION" = "2.4.7" ] || [ "$SPARKVERSION" = "3.0.0" ]; then
  echo "Using Apache Spark version $SPARKVERSION"
else
  	SPARKVERSION="3.0.1"
	echo "Using default Apache Spark version $SPARKVERSION"
fi


if [ "$SPARKVERSION" = "3.0.0" ] || [ "$SPARKVERSION" = "3.0.1" ];then

    SCALAVERSION="2.12.13"

	if [ "$HADOOPVERSION" = "3.2" ];then
		echo "Using Hadoop version $HADOOPVERSION"
	else
       HADOOPVERSION="2.7"
       echo "Using default Hadoop version $HADOOPVERSION"
	fi

else
    SCALAVERSION="2.11.12"
	HADOOPVERSION="2.7"
	echo "Using default Hadoop version $HADOOPVERSION"
	

fi

echo "Using Scala version $SCALAVERSION"

if [ "$PYTHONVERSION" = "3.7" ] || [ "$PYTHONVERSION" = "3.8" ]; then
  echo "Using Python version $PYTHONVERSION"
else
  	PYTHONVERSION="3.9"
	echo "Using default Python version $PYTHONVERSION"
fi




SPARKHADOOP="spark-$SPARKVERSION-bin-hadoop$HADOOPVERSION"
SPARKURL="https://archive.apache.org/dist/spark/spark-$SPARKVERSION/$SPARKHADOOP.tgz"
SCALAURL="https://downloads.lightbend.com/scala/$SCALAVERSION/scala-$SCALAVERSION.tgz"


echo "Apache Spark will be downloaded from: $SPARKURL"
echo "Scala will be downloaded from:$SCALAURL"
echo "A conda environment with name $CONDAENVNAME will be created"

}

install_java()
{
 if [ "$SPARKVERSION" = "3.0.0" ] || [ "$SPARKVERSION" = "3.0.1" ];then
	JAVAVERSION=11
 else
	JAVAVERSION=8
 fi


 sudo apt update
 sudo apt install openjdk-$JAVAVERSION-jdk-headless build-essential

 if [[ ! -d "$JAVA_HOME" ]]; then 
    echo 'export JAVA_HOME="/usr/lib/jvm/java-'$JAVAVERSION'-openjdk-amd64"' >> $HOME/.bashrc
    export JAVA_HOME="/usr/lib/jvm/java-$JAVAVERSION-openjdk-amd64"
 fi

}

install_scala()
{
  cd_sources
  if [ ! -f "scala-$SCALAVERSION.tgz" ]; then
    wget $SCALAURL
  fi 
  
  tar -xvzf scala-$SCALAVERSION.tgz
  sudo mv scala-$SCALAVERSION /opt/scala

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

  cd $HOME

  echo "Creating conda environment" 
  $HOME/miniconda3/bin/conda create -n $CONDAENVNAME python=$PYTHONVERSION
  source $HOME/miniconda3/bin/activate $CONDAENVNAME
  conda install jupyter seaborn pandas scikit-learn
}

reload_env_vars()
{
  echo 'export PATH="$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HOME/miniconda3/bin:$SCALA_HOME/bin:$SPARK_HOME/bin"' >> $HOME/.bashrc
  export PATH="$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$HOME/miniconda3/bin:$SCALA_HOME/bin:$SPARK_HOME/bin"
  cd $SPARK_HOME/python/lib
  PYJ="$(echo py4j*)" 
  echo 'export PYTHONPATH="$SPARK_HOME/python/lib/'$PYJ':$SPARK_HOME/python:$PYTHONPATH"' >> $HOME/.bashrc
  export PYTHONPATH="$SPARK_HOME/python/lib/$PYJ:$SPARK_HOME/python:$PYTHONPATH"
  
  source ~/.bashrc
}


add_pyspark_env_vars()
{
  source $HOME/miniconda3/bin/activate $CONDAENVNAME


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

  cd $HOME
}



add_start_script()
{
 cd $HOME
 touch init_jupyter_spark.sh

 if [ "$NOTEBOOKSPATH" == "" ]; then

 	if [[ -d "/mnt/c" ]]; then
    	NOTEBOOKSPATH="/mnt/c/$NOTEBOOKDIR"
    else
        NOTEBOOKSPATH="$HOME/$NOTEBOOKDIR"
    fi
   

 fi

 echo "jupyter notebooks will be saved on: $NOTEBOOKSPATH"
 mkdir $NOTEBOOKSPATH
 
 cat <<< "source $HOME/miniconda3/bin/activate $CONDAENVNAME
jupyter notebook --no-browser --ip='localhost' --notebook-dir='$NOTEBOOKSPATH' --port=$JUPYTERPORT" > init_jupyter_spark.sh

 chmod +x $HOME/init_jupyter_spark.sh

 echo 'alias start_jupyter=$HOME/init_jupyter_spark.sh' >> $HOME/.bashrc


 echo "execute start_jupyter in wsl shell to run jupyter"
 
 source ~/.bashrc
}


do_installation()
{
init_setup
install_java
install_scala
install_spark
install_miniconda
reload_env_vars

if [ "$JUPYTERINITSCRIPT" = "1" ]; then
	add_pyspark_env_vars
	add_start_script
fi
  


}




usage()
{
    echo "usage: $FILENAME [Note:  { } represents the required parameter (all options are optional)]
	[--conda-env-name {name} conda environment name, default=sparkenv]  
    	[--spark-version {Spark version} --> (2.4.5 | 2.4.6 | 2.4.7 | 3.0.0) default=3.0.1 ]
        [--hadoop-version {Hadoop version} --> (2.7 | 3.2) default=2.7]
        [--python-version {Python version} --> (3.7 | 3.8 | 3.9) default=3.9 ]
	[--create-jupyter-init-script --> create a shell script to initialize jupyter)]
    	[--jupyter-port {int} jupyter web port, necessary only if initialization script is created (default port = 8000)]  
	[--jupyter-notebooks-path {path} path where future notebooks will be created, necessary only if initialization script is created]  
        [-h (help)]"
}

if [ "$1" != "" ];
then

	while [ "$1" != "" ]; do
    		case $1 in

        -sv | --spark-version )      shift
                                	SPARKVERSION=$1
                                	;;
                
	-hv | --hadoop-version )     shift
                                	HADOOPVERSION=$1
                                	;;

	-pv | --python-version )     shift
                                	PYTHONVERSION=$1
                                	;;

        -cn | --conda-env-name )    shift
                                	CONDAENVNAME=$1
                                	;;

        -jp | --jupyter-port )    shift
                                	JUPYTERPORT=$1
                                	;;

        -jn | --jupyter-notebooks-path )    shift
                                	NOTEBOOKSPATH=$1
                                	;;

        -jk | --install-jupyter-spark-kernel )    JUPYTERSPARKKERNEL=1
                                	;;

        -ij | --create-jupyter-init-script )    JUPYTERINITSCRIPT=1
                                	;;

	-h | --help )           usage
                               		exit
                                	;;

       	 * )                    usage
                                	exit 1
    	esac
    	shift
	done

fi


do_installation



