#include < amxmodx >
#include < sqlx >
#include < zombieplague >

#define MAX_CLIENTS		32
#define TASK_LOAD_DATA	12352

#define SQL_HOST 		"n95003a9.beget.tech" // IP/Host бд
#define SQL_USER 		"n95003a9_23" // Логин бд
#define SQL_PASSWORD 	"Lazko2015!" // Пароль бд
#define SQL_DATABASE 	"n95003a9_23" // База данных
#define SQL_TABLENAME	"AmmoPacks"

#define STARTMONEY		50

new bool: g_bUserLoaded[ MAX_CLIENTS + 1 char ];

new g_szName[ MAX_CLIENTS + 1 ][ 34 ];
new g_szQuery[ 512 ]; 

new Handle: g_hDBTuple; 
new Handle: g_hConnect;

public plugin_init( )
{
	register_plugin( "[ZMO] SQL DataBase", "Best", "t3rkecorejz" );
	
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
}
public plugin_cfg( ) SQL_LoadDebug( );
public plugin_end( ) 
{
	if( g_hDBTuple ) 
		SQL_FreeHandle( g_hDBTuple );
	
	if( g_hConnect ) 
		SQL_FreeHandle( g_hConnect );
	
	return;
}

public client_putinserver( iPlayer ) set_task( random_float( 1.0, 3.0 ), "CTask__LoadData", iPlayer +TASK_LOAD_DATA );
public client_disconnect( iPlayer )
{
	if( !g_bUserLoaded{ iPlayer } || is_user_bot( iPlayer ) )
		return;
	
	formatex( g_szQuery, charsmax( g_szQuery ), "UPDATE `%s` SET `Money` = '%d', `ZClass` = '%d' WHERE `%s`.`Name` = '%s';", SQL_TABLENAME, zp_get_user_ammo_packs( iPlayer ), zp_get_user_next_class( iPlayer ), SQL_TABLENAME, g_szName[ iPlayer ] );
	SQL_ThreadQuery( g_hDBTuple, "SQL_ThreadQueryHandler", g_szQuery );
}

// Events
public EV_RoundStart( )
{
	for( new iPlayer = 1; iPlayer <= MAX_CLIENTS; iPlayer++ )
	{
		if( !is_user_connected( iPlayer ) || is_user_bot( iPlayer ) )
			continue;
		
		if( !g_bUserLoaded{ iPlayer } )
			return;
		
		formatex( g_szQuery, charsmax( g_szQuery ), "UPDATE `%s` SET `Money` = '%d', `ZClass` = '%d' WHERE `%s`.`Name` = '%s';", SQL_TABLENAME, zp_get_user_ammo_packs( iPlayer ), zp_get_user_next_class( iPlayer ), SQL_TABLENAME, g_szName[ iPlayer ] );
		SQL_ThreadQuery( g_hDBTuple, "SQL_ThreadQueryHandler", g_szQuery );
	}
}

// Task
public CTask__LoadData( iTask )
{
	new iPlayer = iTask -TASK_LOAD_DATA;
	
	if( !is_user_connected( iPlayer ) || is_user_bot( iPlayer ) )
		return;
	
	new iParams[ 1 ];
	iParams [ 0 ] = iPlayer;
	
	get_user_authid( iPlayer, g_szName[ iPlayer ], charsmax( g_szName[ ] ) );
	
	formatex( g_szQuery, charsmax( g_szQuery ), "SELECT * FROM `%s` WHERE ( `%s`.`Name` = '%s' )", SQL_TABLENAME, SQL_TABLENAME, g_szName[ iPlayer ] );
	SQL_ThreadQuery( g_hDBTuple, "SQL_QueryConnection", g_szQuery, iParams, sizeof iParams );
}

// MySQL
public SQL_LoadDebug( ) 
{
	new szError[ 512 ];
	new iErrorCode;

	g_hDBTuple = SQL_MakeDbTuple( SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DATABASE );
	g_hConnect = SQL_Connect( g_hDBTuple, iErrorCode, szError, charsmax( szError ) );
	
	if( g_hConnect == Empty_Handle )
		set_fail_state( szError );
	
	if( !SQL_TableExists( g_hConnect, SQL_TABLENAME ) )
	{
		new Handle: hQueries; 
		new szQuery[ 512 ];
		
		formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` ( `Name` varchar( 32 ) CHARACTER SET cp1250 COLLATE cp1250_general_ci NOT NULL, `Money` INT NOT NULL, `ZClass` INT NOT NULL)", SQL_TABLENAME );
		hQueries = SQL_PrepareQuery( g_hConnect, szQuery );
		
		if( !SQL_Execute( hQueries ) )
		{
			SQL_QueryError( hQueries, szError, charsmax( szError ) );
			set_fail_state( szError );
		}
		SQL_FreeHandle( hQueries );	
	}
	SQL_QueryAndIgnore( g_hConnect, "SET NAMES utf8" );
}

public SQL_QueryConnection( iState, Handle: hQuery, szError[ ], iErrorCode, iParams[ ], iParamsSize )
{
	switch( iState )
	{
		case TQUERY_CONNECT_FAILED: log_amx( "Load - Could not connect to SQL database. [%d] %s", iErrorCode, szError );
		case TQUERY_QUERY_FAILED: log_amx( "Load Query failed. [%d] %s", iErrorCode, szError );
	}
	
	new iPlayer = iParams[ 0 ];
	g_bUserLoaded{ iPlayer } = true;
	
	if( SQL_NumResults( hQuery ) < 1 )
	{
		if( equal( g_szName[ iPlayer ], "ID_PENDING" ) )
			return PLUGIN_HANDLED;

		zp_set_user_ammo_packs( iPlayer, STARTMONEY );
		zp_set_user_zombie_class( iPlayer, 0 );

		formatex( g_szQuery, charsmax( g_szQuery ), "INSERT INTO `%s` ( `Name`, `Money`, `ZClass` ) VALUES ( '%s', '%d', '%d' );", SQL_TABLENAME, g_szName[ iPlayer ], zp_get_user_ammo_packs( iPlayer ), zp_get_user_next_class( iPlayer ) );
		SQL_ThreadQuery( g_hDBTuple, "SQL_ThreadQueryHandler", g_szQuery );
		
		return PLUGIN_HANDLED;
	}
	else 
	{
		zp_set_user_ammo_packs( iPlayer, SQL_ReadResult( hQuery, 1 ) );
		zp_set_user_zombie_class( iPlayer, SQL_ReadResult( hQuery, 2 ) );
	}
	
	return PLUGIN_HANDLED;
}

public SQL_ThreadQueryHandler( iState, Handle: hQuery, szError[ ], iErrorCode, iParams[ ], iParamsSize )
{
	if( iState == 0 )
		return;
	
	log_amx( "SQL Error: %d (%s)", iErrorCode, szError );
}

// Stocks
stock bool: SQL_TableExists( Handle: hDataBase, const szTable[ ] )
{
	new Handle: hQuery = SQL_PrepareQuery( hDataBase, "SELECT * FROM information_schema.tables WHERE table_name = '%s' LIMIT 1;", szTable );
	new szError[ 512 ];
    
	if( !SQL_Execute( hQuery ) )
	{
		SQL_QueryError( hQuery, szError, charsmax( szError ) );
		set_fail_state( szError );
	}
	else if( !SQL_NumResults( hQuery ) )
	{
		SQL_FreeHandle( hQuery );
		return false;
	}
	
	SQL_FreeHandle( hQuery );
	return true;
}
