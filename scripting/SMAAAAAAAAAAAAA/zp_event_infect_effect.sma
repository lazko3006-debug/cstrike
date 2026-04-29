#include <amxmodx> 
#include <fakemeta>
#include <zombieplague> 

new sprites_number1, sprites_number2

new const z_sprites1[] = "sprites/biohazard/poison_spr.spr" 

new const z_sprites2[] = "sprites/biohazard/poison_flare.spr"

public plugin_init()
{
    register_plugin("Infect Effect Sprites", "1.0", "Krtola")
}

public plugin_precache() 
{     
    sprites_number1 = precache_model(z_sprites1)  
    sprites_number2 = engfunc(EngFunc_PrecacheModel, z_sprites2)
}

public zp_user_infected_post(id)
{
    new Float:vOrigin[3] 
    pev(id, pev_origin, vOrigin)

    if(zp_get_user_zombie(id))
    {      
        sprite_play_animation(vOrigin, 40.0)
        sprites_play_animation2(id)
    }
}

sprite_play_animation(const Float:vOrigin[3], Float:Add) 
{ 
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0) 
    write_byte(TE_SPRITE) 
    engfunc(EngFunc_WriteCoord, vOrigin[0]) 
    engfunc(EngFunc_WriteCoord, vOrigin[1]) 
    engfunc(EngFunc_WriteCoord, vOrigin[2] + Add) 
    write_short(sprites_number1) 
    write_byte(8) 
    write_byte(200) 
    message_end() 
}


sprites_play_animation2(id) 
{ 
        new Float:vOrigin[3]

        set_pev(id, pev_iuser2, 0) 
        pev(id, pev_origin, vOrigin)  

        message_begin (MSG_BROADCAST,SVC_TEMPENTITY) 
        write_byte( TE_SPRITETRAIL ) // Throws a shower of sprites or models 
        write_coord( floatround(vOrigin[ 0 ]) ) // start pos 
        write_coord( floatround(vOrigin[ 1 ]) ) 
        write_coord( floatround(vOrigin[ 2 ]) ) 
        write_coord( floatround(vOrigin[ 0 ]) ) // velocity 
        write_coord( floatround(vOrigin[ 1 ]) ) 
        write_coord( floatround(vOrigin[ 2 ]) +20) 
        write_short(sprites_number2) // spr 
        write_byte(15) // (count) 
        write_byte(random_num(2,3)) // (life in 0.1's) 
        write_byte(2) // byte (scale in 0.1's) 
        write_byte(random_num(20,30)) // (velocity along vector in 10's) 
        write_byte(15) // (randomness of velocity in 10's) 
        message_end()
}