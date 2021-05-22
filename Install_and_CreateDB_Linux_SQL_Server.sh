#!/bin/bash

function install_MSSQL()
{
	clear
	echo -e "\n\n\t\t----------------- Start install_MSSQL --------------------"

	echo -e "\n\n\t\tInstalling MS SQL Server\n\n\t\tPlease Follow Instructions";	
	# To Install MS-SQL on Linux
	# Refernce	:	https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-red-hat?view=sql-server-2017
	sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo
	sudo yum install -y mssql-server

	echo -e "\n\n\t\t( Please ENTER 1 ( one, Evaluation ) in edition )\n\n"
	sudo /opt/mssql/bin/mssql-conf setup


		clear
		# Verify Running
		systemctl status mssql-server

	# Below Full text Search installation is not required but Optional
		# install full text search for sql server
		sudo yum install -y mssql-server-fts

		# Check for Update
		sudo yum check-update
		sudo yum update mssql-server-fts
		
		$(install_MSSQL_TOOLS)
	
	
	echo -e "================== END install_MSSQL ======================"
} >&2

function install_MSSQL_TOOLS()
{
	clear
	echo -e "\n\n\t\t----------------- Start install_MSSQL_TOOLS --------------------"

	echo -e "\n\n\t\tInstalling MS SQL Client ( sqlcmd )\n\n\t\tPlease Follow Instructions";
	# Install MS SQL Tools

	sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
	sudo yum remove unixODBC-utf16 unixODBC-utf16-devel
	sudo yum install -y mssql-tools unixODBC-devel

	echo export PATH='$PATH:/opt/mssql-tools/bin' >> ~/.bash_profile
	echo export PATH='$PATH:/opt/mssql-tools/bin' >> ~/.bashrc
	
	. ~/.bashrc
	. ~/.bash_profile

		# Verify
		#sqlcmd -S localhost -U SA -P '<YourPassword>'
	
	
	echo -e "================== END install_MSSQL_TOOLS ======================"
} >&2

function SetUp()
{
	echo -e "\n\n\t\t----------------- Start SetUp --------------------"

	# Install MS-SQL
	echo "Do You Want to install MSSQL ( Press Y to install new ) ?"
	read Yes
	
	if [[ M"$Yes" != "MY" ]]; then
		echo "Do You want to install SQL CMD ( Press Y to install ) ?"
		read cmd
		if [[ B"$cmd" != "BY" ]]; then
			echo -e "\n\n\tAssuming MSSQL Server and Client is Already installed.\n\n"
		else
			# Install MSSQL-TOOLS ( SQLCMD )
			$(install_MSSQL_TOOLS)
		fi
		else
			# Install MS-SQL and MSSQL-TOOL ( SQLCMD )
			$(install_MSSQL)			
	fi


	echo -e "================== END SetUp ======================"

} >&2

function GenrateSQLs()
{
	echo -e "\n\n\t\t----------------- Start GenrateSQLs --------------------" >&2

	# Generating SQLs for Database Creation on Linux
		Running=`systemctl status mssql-server | grep running`
		if [[ M"$Running" != "M" ]]; then
			echo -e "\n\n\t\tEnter Name Of Database to be Created" >&2
			read DB
			echo "$DB" >&2

			#echo "Enter Database User Password for User $DB"
			#read Password
			
			# Give Permisions to Dirctory
			sudo chown -R mssql:root /opt/mssql

			# Create Directory for Database Files
                        sudo mkdir -p /opt/mssql/installation
			
			# Give appropriate permissions to mssql user
			sudo chown -R mssql:root /opt/mssql 

			# Generated SQL File Name
			GENERATED_SQL=Generated_"$DB".sql
			> $GENERATED_SQL
			
			# SQL Generation
			
				echo -e "\n\n-- Enble Contained Database Authentication\n" >> $GENERATED_SQL
					echo "sp_configure 'contained database authentication', 1;" >> $GENERATED_SQL
					echo "GO" >> $GENERATED_SQL
					echo "RECONFIGURE ;" >> $GENERATED_SQL
					echo "GO" >> $GENERATED_SQL
					
				echo -e "\n\n-- Create Database\n" >> $GENERATED_SQL

					echo "USE [master]" >> $GENERATED_SQL
					echo "GO" >> $GENERATED_SQL
					echo "CREATE DATABASE [$DB] " >> $GENERATED_SQL 
					echo "GO" >> $GENERATED_SQL
			
				echo "Generated SQLs for Database Creation ( $GENERATED_SQL ) with User = $DB, Password = $DB" >&2
				echo $GENERATED_SQL
				
		else
			echo -e "\n\n\t MSSQL Server is not Running\nPlease check whether it is installed and Running.\n\n\n";
			echo -e "\t\t Please check Location /opt/mssql/bin/sqlservr and /opt/mssql-tools/bin/sqlcmd\n\n\n";
		fi


		echo -e "\n\n\t\t================== END GenrateSQLs ======================" >&2
}

# Un Install MSSQL, If Needed
function unInstall_MSSQL()
{
	sudo yum remove mssql-server
	sudo rm -rf /var/opt/mssql/
	
	$(unInstall_MSSQL_TOOLS)
}

# Un Install MSSQL TOOLS, If Needed
function unInstall_MSSQL_TOOLS()
{
	sudo yum remove mssql-tools
}

echo -e "\n\n\t\t----------------- Start $0 --------------------"

	$(SetUp)

	Generated=$(GenrateSQLs)

	echo "Enter SA User Password"
	read -s SAPassword
	echo

	/opt/mssql-tools/bin/sqlcmd -U SA -P $SAPassword -i $Generated

	# If You have permision problem
	# Execute Below Commands and Reload Vagrant


echo -e "\n\n\t\t================== END $0 ======================"