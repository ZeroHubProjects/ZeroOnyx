/obj/mecha/combat/honker
	desc = "Produced by \"Tyranny of Honk, INC\", this exosuit is designed as heavy clown-support. Used to spread the fun and joy of life. HONK!"
	name = "H.O.N.K"
	icon_state = "honker"
	initial_icon = "honker"
	base_color = "#BD0F17"
	step_in = 2
	health = 200
	deflect_chance = 60
	internal_damage_threshold = 60
	damage_absorption = list("brute" = 1.2, "fire" = 1.5, "bullet" = 1, "laser" = 1, "energy" = 1, "bomb" = 1)
	max_temperature = 25500
	infra_luminosity = 5
	operation_req_access = list(access_clown)
	wreckage = /obj/effect/decal/mecha_wreckage/honker
	add_req_access = 0
	max_equip = 3
	var/squeak = 0

/obj/mecha/combat/honker/melee_action(target)
	if(!melee_can_hit)
		return
	else if(istype(target, /mob))
		step_away(target, src, 15)
	return

/obj/mecha/combat/honker/get_stats_part()
	var/cell_charge = get_charge()
	var/output = {"[internal_damage&MECHA_INT_FIRE?"<font color='red'><b>INTERNAL FIRE</b></font><br>":null]
						[internal_damage&MECHA_INT_TEMP_CONTROL?"<font color='red'><b>CLOWN SUPPORT SYSTEM MALFUNCTION</b></font><br>":null]
						[internal_damage&MECHA_INT_TANK_BREACH?"<font color='red'><b>GAS TANK HONK</b></font><br>":null]
						[internal_damage&MECHA_INT_CONTROL_LOST?"<font color='red'><b>HONK-A-DOODLE</b></font> - <a href='byond://?src=\ref[src];repair_int_control_lost=1'>Recalibrate</a><br>":null]
						<b>IntegriHONK: </b> [health/initial(health)*100] %) <br>
						<b>PowerHONK charge: </b>[isnull(cell_charge)?"Someone HONKed powerHonk!!!":"[cell.percent()]%"])<br>
						<b>Air source: </b>[use_internal_tank?"Internal AirHONK":"EnvironHONK"]<br>
						<b>AirHONK pressure: </b>[src.return_pressure()]HoNKs<br>
						<b>Internal HONKature: </b> [src.return_temperature()]&deg;honK|[CONV_KELVIN_CELSIUS(src.return_temperature())]&deg;honCk<br>
						<b>Lights: </b>[lights?"on":"off"]<br>
					"}
	return output

/obj/mecha/combat/honker/get_stats_html()
	var/output = {"<html>
						<head><title>[src.name] data</title>
						<style>
						.wr {margin-bottom: 5px;}
						.header {cursor:pointer;}
						.open, .closed {background: #32CD32; color:#000; padding:1px 2px;}
						.links a {margin-bottom: 2px;}
						.visible {display: block;}
						.hidden {display: none;}
						</style>
						<script language='javascript' type='text/javascript'>
						[js_byjax]
						[js_dropdowns]
						function ticker() {
						    setInterval(function(){
						        window.location='byond://?src=\ref[src]&update_content=1';
						        document.body.style.color = get_rand_color_string();
								  document.body.style.background = get_rand_color_string();

						    }, 1000);
						}

						function get_rand_color_string() {
						    var color = new Array;
						    for(var i=0;i<3;i++){
						        color.push(Math.floor(Math.random()*255));
						    }
						    return "rgb("+color.toString()+")";
						}

						window.onload = function() {
							dropdowns();
							ticker();
						}
						</script>
						</head>
						<body style="color: #fff; background: #000; font: 14px 'Courier', monospace;">
						<div id='content'>
						[src.get_stats_part()]
						</div>
						<div id='eq_list'>
						[src.get_equipment_list()]
						</div>
						<hr>
						[src.get_commands()]
						</body>
						</html>
					 "}
	return output

/obj/mecha/combat/honker/get_commands()
	var/output = {"<div class='wr'>
						<div class='header'>Sounds of HONK:</div>
						<div class='links'>
						<a href='byond://?src=\ref[src];play_sound=sadtrombone'>Sad Trombone</a>
						</div>
						</div>
						"}
	output += ..()
	return output

/obj/mecha/combat/honker/get_equipment_list()
	if(!equipment.len)
		return
	var/output = "<b>Honk-ON-Systems:</b><div style=\"margin-left: 15px;\">"
	for(var/obj/item/mecha_parts/mecha_equipment/MT in equipment)
		output += "[selected==MT?"<b id='\ref[MT]'>":"<a id='\ref[MT]' href='byond://?src=\ref[src];select_equip=\ref[MT]'>"][MT.get_equip_info()][selected==MT?"</b>":"</a>"]<br>"
	output += "</div>"
	return output

/obj/mecha/combat/honker/mechstep(direction)
	var/result = step(src, direction)
	if(result)
		if(!squeak)
			playsound(src, SFX_CLOWN, 70, 1)
			squeak = 1
		else
			squeak = 0
	return result

/obj/mecha/combat/honker/Topic(href, href_list)
	..()
	if(href_list["play_sound"])
		switch(href_list["play_sound"])
			if("sadtrombone")
				playsound(src, 'sound/misc/sadtrombone.ogg', 100)
	return

/proc/rand_hex_color()
	var/list/colors = list("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f")
	var/color=""
	for(var/i in 0 to 5)
		color = color+pick(colors)
	return color
