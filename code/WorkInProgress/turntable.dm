#define TURNTABLE_CHANNEL 10

/mob/var/sound/music

/datum/turntable_soundtrack
	var/f_name
	var/name
	var/path

/obj/machinery/party/turntable
	name = "Jukebox"
	desc = "A jukebox is a partially automated music-playing device, usually a coin-operated machine, that will play a patron's selection from self-contained media."
	icon = 'icons/obj/objects.dmi'
	icon_state = "Jukebox"
	var/playing = 0
	var/datum/turntable_soundtrack/track = null
	var/volume = 100
	var/list/turntable_soundtracks = list()
	anchored = 1
	density = 1

/obj/machinery/party/turntable/New()
	..()
	for(var/obj/machinery/party/turntable/TT) // Rework it later
		if(TT != src)
			del(src)
	turntable_soundtracks = list()
	for(var/i in typesof(/datum/turntable_soundtrack) - /datum/turntable_soundtrack)
		var/datum/turntable_soundtrack/D = new i()
		if(D.path)
			turntable_soundtracks.Add(D)

/obj/machinery/party/turntable/attack_paw(user as mob)
	return src.attack_hand(user)

/obj/machinery/party/turntable/attack_hand(mob/living/user as mob)
	if (..())
		return

	usr.set_machine(src)
	src.add_fingerprint(usr)

	var/t = "<body background='turntable_back.jpg'><br><br><br><div align='center'><table border='0'><B><font color='maroon' size='6'>J</font><font size='5' color='purple'>uke Box</font> <font size='5' color='green'>Interface</font></B><br><br><br><br>"
	t += "<tr><td height='50' weight='50'></td><td height='50' weight='50'><A href='?src=\ref[src];off=1'><font color='maroon'>T</font><font color='lightgreen'>urn</font> <font color='red'>Off</font></A></td><td height='50' weight='50'></td></tr>"
	t += "<tr>"


	var/lastcolor = "green"
	for(var/i = 10; i <= 100; i += 10)
		t += "<A href='?src=\ref[src];set_volume=[i]'><font color='[lastcolor]'>[i]</font></A> "
		if(lastcolor == "green")
			lastcolor = "purple"
		else
			lastcolor = "green"

	var/i = 0
	for(var/datum/turntable_soundtrack/D in turntable_soundtracks)
		t += "<td height='50' weight='50'><A href='?src=\ref[src];on=\ref[D]'><font color='maroon'>[D.f_name]</font><font color='[lastcolor]'>[D.name]</font></A></td>"
		i++
		if(i == 1)
			lastcolor = pick("lightgreen", "purple")
		else
			lastcolor = pick("green", "purple")
		if(i == 3)
			i = 0
			t += "</tr><tr>"

	t += "</table></div></body>"
	user << browse(t, "window=turntable;size=450x700;can_resize=0")
	onclose(user, "turntable")
	return

/obj/machinery/party/turntable/power_change()
	turn_off()

/obj/machinery/party/turntable/Topic(href, href_list)
	if(..())
		return
	if(href_list["on"])
		turn_on(locate(href_list["on"]))

	else if(href_list["off"])
		turn_off()

	else if(href_list["set_volume"])
		set_volume(text2num(href_list["set_volume"]))

/obj/machinery/party/turntable/process()
	if(playing)
		update_sound()

/obj/machinery/party/turntable/proc/turn_on(var/datum/turntable_soundtrack/selected)
	if(playing)
		turn_off()
	if(selected)
		track = selected
	if(!track)
		return

	for(var/mob/M)
		create_sound(M)
	update_sound()

	var/area/A = get_area(src)

	playing = 1
	process()

/obj/machinery/party/turntable/proc/turn_off()
	if(!playing)
		return
	for(var/mob/M)
		M.music = null
		M << sound(null, channel = TURNTABLE_CHANNEL, wait = 0)

	playing = 0
	var/area/A = get_area(src)

/obj/machinery/party/turntable/proc/set_volume(var/new_volume)
	volume = max(0, min(100, new_volume))
	if(playing)
		update_sound(1)

/obj/machinery/party/turntable/proc/update_sound(update = 0)
	var/area/A = get_area(src)
	for(var/mob/M)
		var/inRange = (get_area(M) in A.related)
		if(!M.music)
			create_sound(M)
			continue
		if(inRange && (M.music.volume != volume || update))
			M.music.status = SOUND_UPDATE//|SOUND_STREAM
			M.music.volume = volume
			M << M.music
		else if(!inRange && M.music.volume != 0)
			M.music.status = SOUND_UPDATE//|SOUND_STREAM
			M.music.volume = 0
			M << M.music

/obj/machinery/party/turntable/proc/create_sound(mob/M)
	var/sound/S = sound(track.path)
	S.repeat = 1
	S.channel = TURNTABLE_CHANNEL
	S.falloff = 2
	S.wait = 0
	S.volume = 0
	S.status = 0 //SOUND_STREAM
	M.music = S
	M << S