#include < amxmodx >
#include < dhudmessage >
#include < zombieplague >

#define PLUGIN_NAME "[ZP]Informer"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "max99"

enum _: eTeamData
{
	WIN_NO_ONE = 0,
	WIN_ZOMBIES,
	WIN_HUMANS	

}; new g_iWin[ eTeamData ];

public plugin_init() 
{
    	register_plugin
	( 
		PLUGIN_NAME, 
		PLUGIN_VERSION, 
		PLUGIN_AUTHOR
	);

	register_dictionary( "zp_score.txt" );
	register_message( get_user_msgid( "TextMsg" ), "Message_TextMsg" );
}

public Message_TextMsg( ) 
{
	static szMessages[ 32 ];
	get_msg_arg_string( 2, szMessages, charsmax( szMessages ) );
	
	if( equal( szMessages, "#Game_will_restart_in" ) )
	{
		g_iWin[ WIN_HUMANS ] = 0;
		g_iWin[ WIN_ZOMBIES ] = 0;
		g_iWin[ WIN_NO_ONE ] = 0;
	} 
}

public zp_round_started( )
{
	set_task( 1.0, "Ctask__Update", _ ,_ ,_ , .flags = "b" );
}  

public zp_round_ended( iWinTeam )
{
	switch( iWinTeam )
	{
		case WIN_HUMANS: g_iWin[ WIN_HUMANS ]++;
		case WIN_ZOMBIES: g_iWin[ WIN_ZOMBIES ]++;
		default: g_iWin[ WIN_NO_ONE ]++;
	}

	remove_task();
}  


public Ctask__Update( )
{
	set_dhudmessage( .red = 0, .green = 255, .blue = 0, .x = 0.35, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.0, .fadeintime = 1.0, .fadeouttime = 1.0, .reliable = false ); 
	show_dhudmessage( 0, "%L", LANG_PLAYER, "SCORE_HUMANS", zp_get_human_count() );
	set_dhudmessage( .red = 255, .green = 255, .blue = 255, .x = -1.0, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.0, .fadeintime = 1.0, .fadeouttime = 1.0, .reliable = false ); 
	show_dhudmessage( 0, "%L", LANG_PLAYER, "SCORE_ROUND", ( g_iWin[ WIN_HUMANS ] +  g_iWin[ WIN_ZOMBIES ] + g_iWin[ WIN_NO_ONE ] ), LANG_PLAYER,  "SCORE_WINS", g_iWin[ WIN_HUMANS ],  g_iWin[ WIN_ZOMBIES ] );
	set_dhudmessage( .red = 255, .green = 0, .blue = 0, .x = 0.58, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.0, .fadeintime = 1.0, .fadeouttime = 1.0, .reliable = false ); 
	show_dhudmessage( 0, "%L", LANG_PLAYER, "SCORE_ZOMBIES", zp_get_zombie_count() );
}