#define NO_SCREEN 0
#define CHANGE_SECURITY_LEVEL 1
#define TRANSFER_FUNDS 2
#define VIEW_TRANSACTION_LOGS 3

/obj/item/card/id/var/money = 2000

/obj/machinery/atm
	name = "Automatic Teller Machine"
	desc = "For all your monetary needs!"
	icon = 'icons/obj/terminals.dmi'
	icon_state = "atm"
	anchored = TRUE
	idle_power_usage = 10 WATTS
	layer = ABOVE_WINDOW_LAYER
	var/datum/money_account/authenticated_account
	var/number_incorrect_tries = 0
	var/previous_account_number = 0
	var/max_pin_attempts = 3
	var/ticks_left_locked_down = 0
	var/ticks_left_timeout = 0
	var/machine_id = ""
	var/obj/item/card/held_card
	var/editing_security_level = BANK_SECURITY_MINIMUM
	var/view_screen = NO_SCREEN
	var/datum/effect/effect/system/spark_spread/spark_system
	var/account_security_level = BANK_SECURITY_MINIMUM

/obj/machinery/atm/New()
	..()
	machine_id = "[station_name()] ATM #[num_financial_terminals++]"
	spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/machinery/atm/Destroy()
	authenticated_account = null
	QDEL_NULL(spark_system)
	QDEL_NULL(held_card)
	return ..()

/obj/machinery/atm/Process()
	if(stat & NOPOWER)
		return

	if(ticks_left_timeout > 0)
		ticks_left_timeout--
		if(ticks_left_timeout <= 0)
			authenticated_account = null
	if(ticks_left_locked_down > 0)
		ticks_left_locked_down--
		if(ticks_left_locked_down <= 0)
			number_incorrect_tries = 0

	for(var/obj/item/spacecash/S in src)
		S.loc = src.loc
		if(prob(50))
			playsound(loc, 'sound/items/polaroid1.ogg', 50, 1)
		else
			playsound(loc, 'sound/items/polaroid2.ogg', 50, 1)
		break

/obj/machinery/atm/emag_act(remaining_charges, mob/user)
	if(!emagged)
		playsound(src.loc, 'sound/effects/computer_emag.ogg', 25)
		//short out the machine, shoot sparks, spew money!
		emagged = 1
		spark_system.start()
		spawn_money(rand(100,500),src.loc)
		//we don't want to grief people by locking their id in an emagged ATM
		release_held_id(user)

		//display a message to the user
		var/response = pick("Initiating withdraw. Have a nice day!", "CRITICAL ERROR: Activating cash chamber panic siphon.","PIN Code accepted! Emptying account balance.", "Jackpot!")
		to_chat(user, "\icon[src] [SPAN("warning", "The [src] beeps: \"[response]\"")]")
		return 1

/obj/machinery/atm/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/card))
		if(emagged > 0)
			//prevent inserting id into an emagged ATM
			to_chat(user, "\icon[src] [SPAN("warning", "CARD READER ERROR. This system has been compromised!")]")
			return

		var/obj/item/card/id/idcard = I
		if(!held_card && usr.drop(idcard, src))
			held_card = idcard
			if(authenticated_account && held_card.associated_account_number != authenticated_account.account_number)
				authenticated_account = null
			attack_hand(user)

	else if(authenticated_account)
		if(istype(I,/obj/item/spacecash))
			var/obj/item/spacecash/dolla = I
			if(prob(50))
				playsound(loc, 'sound/items/polaroid1.ogg', 50, 1)
			else
				playsound(loc, 'sound/items/polaroid2.ogg', 50, 1)

			//create a transaction log entry
			var/datum/transaction/T = new(authenticated_account.owner_name, "Credit deposit", dolla.worth, machine_id)
			authenticated_account.do_transaction(T)

			to_chat(user, SPAN("info", "You insert [I] into [src]."))
			src.attack_hand(user)
			dolla.worth = 0
			qdel(I)
	else
		..()

/obj/machinery/atm/attack_hand(mob/user)
	if(!..())
		interact(user)

/obj/machinery/atm/interact(mob/user)

	if(istype(user, /mob/living/silicon))
		to_chat(user, "\icon[src] [SPAN("warning", "Artificial unit recognized. Artificial units do not currently receive monetary compensation, as per system banking regulation #1005.")]")
		return

	if(in_range(src,user))
		//make the window the user interacts with, divided out into welcome message, card 'slot', then login/data screen
		var/list/t = list()

		if(authenticated_account)
			t += "[SPAN("highlight", "Welcome <b>[authenticated_account.owner_name]</b>.")]<BR>"
		else
			t += "[SPAN("highlight", "Welcome. Please login below.")]<BR>"

		t += "<div class='statusDisplay'>[SPAN("highlight", "<b>Card: </b>")]"
		if(emagged > 0)
			t += "[SPAN("bad", "<b>LOCKED</b><br>Unauthorized terminal access detected!<br>This ATM has been locked down.")]</div><BR>"
		else
			t += "<a href='byond://?src=\ref[src];choice=insert_card'>[held_card ? held_card.name : "No card inserted"]</a></div><BR>"
			t += "<div class='statusDisplay'>"
			if(ticks_left_locked_down > 0)
				t += "[SPAN("bad", "Maximum number of pin attempts exceeded! Access to this ATM has been temporarily disabled.")]</div>"
			else if(authenticated_account)
				if(authenticated_account.suspended)
					t += "[SPAN("bad", "<b>Access to this account has been suspended, and the funds within frozen.</b>")]</div>"
				else
					switch(view_screen)
						if(CHANGE_SECURITY_LEVEL)
							t += "Select a new security level for this account:<br><hr>"
							if(authenticated_account.security_level != BANK_SECURITY_MINIMUM)
								t += "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=0'>Select Minimum Security</a><BR>"
							else
								t += "[SPAN("good", "<b>Minimum security set: </b>")]<BR>"
							t += "Either the account number or card is required to access this account. EFTPOS transactions will require a card and ask for a pin, but not verify the pin is correct.<hr>"
							if(authenticated_account.security_level != BANK_SECURITY_MODERATE)
								t += "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=1'>Select Moderate Security</a><BR>"
							else
								t += "[SPAN("average", "<b>Moderate Security set: </b>")]<BR>"
							t += "An account number and pin must be manually entered to access this account and process transactions.<hr>"
							if(authenticated_account.security_level != BANK_SECURITY_MAXIMUM)
								t += "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=2'>Select Maximum Security</a><BR>"
							else
								t += "[SPAN("bad", "<b>Maximum security Set: </b>")]<BR>"
							t += "High - In addition to account number, a pin and a card is required to access this account and process transactions.<hr><br>"
						if(VIEW_TRANSACTION_LOGS)
							t += "<b>Transaction logs</b><br>"
							t += "<table border=1 style='width:100%'>"
							t += "<tr>"
							t += "<td><b>Date</b></td>"
							t += "<td><b>Time</b></td>"
							t += "<td><b>Target</b></td>"
							t += "<td><b>Purpose</b></td>"
							t += "<td><b>Value</b></td>"
							t += "<td><b>Source terminal ID</b></td>"
							t += "</tr>"
							for(var/datum/transaction/T in authenticated_account.transaction_log)
								t += "<tr>"
								t += "<td>[T.date]</td>"
								t += "<td>[T.time]</td>"
								t += "<td>[T.target_name]</td>"
								t += "<td>[T.purpose]</td>"
								t += "<td>[T.amount]cr.</td>"
								t += "<td>[T.source_terminal]</td>"
								t += "</tr>"
							t += "</table>"
							t += "<A href='byond://?src=\ref[src];choice=print_transaction'>Print</a><br>"
						if(TRANSFER_FUNDS)
							t += "<b>Account balance:</b> [authenticated_account.money]cr.<br>"
							t += "<form name='transfer' action='byond://?src=\ref[src]' method='get'>"
							t += "<input type='hidden' name='src' value='\ref[src]'>"
							t += "<input type='hidden' name='choice' value='transfer'>"
							t += "Target account number: <input type='text' name='target_acc_number' value='' style='width:200px; background-color:white;'><br>"
							t += "Funds to transfer: <input type='text' name='funds_amount' value='' style='width:200px; background-color:white;'><br>"
							t += "Transaction purpose: <input type='text' name='purpose' value='Funds transfer' style='width:200px; background-color:white;'><br>"
							t += "<input type='submit' value='Transfer funds'><br>"
							t += "</form>"
						else
							t += "<b>Account balance:</b> [authenticated_account.money]cr."
							t += "<form name='withdrawal' action='byond://?src=\ref[src]' method='get'>"
							t += "<input type='hidden' name='src' value='\ref[src]'>"
							t += "<input type='radio' name='choice' value='withdrawal' checked> Cash  <input type='radio' name='choice' value='e_withdrawal'> Chargecard<br>"
							t += "<input type='text' name='funds_amount' value='' style='width:200px; background-color:white;'><input type='submit' value='Withdraw'>"
							t += "</form>"
							t += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=1'>Change account security level</a><br>"
							t += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=2'>Make transfer</a><br>"
							t += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=3'>View transaction log</a><br>"
							t += "<A href='byond://?src=\ref[src];choice=balance_statement'>Print balance statement</a><br>"

					//Logout/back buttons, put here for some modularity and for less repeated code
					if(view_screen == NO_SCREEN)
						t += "<A href='byond://?src=\ref[src];choice=logout'>Logout</a><br></div>"
					else
						t += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=0'>Back</a></div>"

			else
				//change our display depending on account security levels
				switch(account_security_level)
					if(BANK_SECURITY_MINIMUM)
						t += "To log in to your savings account, press 'submit' with ID clearly displayed. If you wish to log into another account, please enter the account number into the field below or insert a registered ID card into the slot above and then press 'submit'.<BR>"
					if(BANK_SECURITY_MODERATE)
						t += "This account requires a PIN to access. For security reasons the account # will need re-entered or ID bound to this account re-scanned."
					if(BANK_SECURITY_MAXIMUM)
						t += "[SPAN("bad", "<b>Due to the security settings on this account, all information needs to be re-entered and the ID bound to this account placed in the slot above.</b>")]<BR>"
				t += "<form name='atm_auth' action='byond://?src=\ref[src]' method='get'>"
				t += "<input type='hidden' name='src' value='\ref[src]'>"
				t += "<input type='hidden' name='choice' value='attempt_auth'>"
				t += "<b>Account:</b> <input type='text' id='account_num' name='account_num' style='width:250px; background-color:white;'><BR><BR>"
				//Leave the PIN field out of sight until needed
				if(account_security_level != BANK_SECURITY_MINIMUM)
					t += "<b>PIN:</b> <input type='text' id='account_pin' name='account_pin' style='width:250px; background-color:white;'><BR><BR>"
				t += "<input type='submit' value='Submit'><br>"
				t += "</div></form>"


		var/datum/browser/popup = new(user, "ATM", machine_id)
		popup.set_content(jointext(t,null))
		popup.open()
	else
		return

/obj/machinery/atm/Topic(href, href_list)
	if(!in_range(src, usr))
		to_chat(usr, "\icon[src][SPAN("warning", "You have to remain closer to the [src]!")]")
		return 0
	if(href_list["choice"])
		switch(href_list["choice"])
			if("transfer")
				if(authenticated_account)
					var/transfer_amount = text2num(href_list["funds_amount"])
					transfer_amount = round(transfer_amount, 0.01)
					if(transfer_amount <= 0)
						alert("That is not a valid amount.")
					else if(transfer_amount <= authenticated_account.money)
						var/target_account_number = text2num(href_list["target_acc_number"])
						var/transfer_purpose = sanitizeSafe(href_list["purpose"])
						if(charge_to_account(target_account_number, authenticated_account.owner_name, transfer_purpose, machine_id, transfer_amount))
							to_chat(usr, "\icon[src][SPAN("info", "Funds transfer successful.")]")
							//create an entry in the account transaction log
							var/datum/transaction/T = new("Account #[target_account_number]", transfer_purpose, -transfer_amount, machine_id)
							authenticated_account.do_transaction(T)
						else
							to_chat(usr, "\icon[src][SPAN("warning", "Funds transfer failed.")]")

					else
						to_chat(usr, "\icon[src][SPAN("warning", "You don't have enough funds to do that!")]")
			if("view_screen")
				view_screen = text2num(href_list["view_screen"])
			if("change_security_level")
				if(authenticated_account)
					var/new_sec_level = max( min(text2num(href_list["new_security_level"]), 2), 0)
					authenticated_account.security_level = new_sec_level
			if("attempt_auth")

				//Look to see if we're holding an ID, if so scan the data from that and use it, if not scan the user for the data
				var/obj/item/card/id/login_card
				if(held_card)
					login_card = held_card
				else
					login_card = scan_user(usr)

				if(!ticks_left_locked_down)
					var/tried_account_num = text2num(href_list["account_num"])
					//We WILL need an account number entered manually if security is high enough, do not automagic account number
					if(!tried_account_num && login_card && (account_security_level != BANK_SECURITY_MAXIMUM))
						tried_account_num = login_card.associated_account_number
					var/tried_pin = text2num(href_list["account_pin"])

					//We'll need more information if an account's security is greater than zero so let's find out what the security setting is
					var/datum/money_account/D
					//Below is to avoid a runtime
					if(tried_account_num)
						D = get_account(tried_account_num)
						if(D?.security_level)
							account_security_level = D.security_level

					authenticated_account = attempt_account_access(tried_account_num, tried_pin, held_card && login_card.associated_account_number == tried_account_num ? 2 : 1)

					if(!authenticated_account)
						number_incorrect_tries++
						//let's not count an incorrect try on someone who just needs to put in more information
						if(previous_account_number == tried_account_num && tried_pin)
							if(number_incorrect_tries >= max_pin_attempts)
								//lock down the atm
								ticks_left_locked_down = 30
								playsound(src, 'sound/machines/buzz-two.ogg', 50, 1)

								//create an entry in the account transaction log
								var/datum/money_account/failed_account = get_account(tried_account_num)
								if(failed_account)
									var/datum/transaction/T = new(failed_account.owner_name, "Unauthorised login attempt", 0, machine_id)
									failed_account.do_transaction(T)
							else
								to_chat(usr, "\icon[src] [SPAN("warning", "Incorrect pin/account combination entered, [max_pin_attempts - number_incorrect_tries] attempts remaining.")]")
								previous_account_number = tried_account_num
								playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 1)
						else
							to_chat(usr, "\icon[src] [SPAN("warning", "Unable to log in to account, additional information may be required.")]")
							number_incorrect_tries = 0
					else
						playsound(src, 'sound/signals/ping6.ogg', 50, 0)
						ticks_left_timeout = 120
						view_screen = NO_SCREEN

						//create a transaction log entry
						var/datum/transaction/T = new(authenticated_account.owner_name, "Remote terminal access", 0, machine_id)
						authenticated_account.do_transaction(T)

						to_chat(usr, "\icon[src] [SPAN("info", "Access granted. Welcome user '[authenticated_account.owner_name].'")]")

					previous_account_number = tried_account_num
			if("e_withdrawal")
				var/amount = max(text2num(href_list["funds_amount"]),0)
				amount = round(amount, 0.01)
				if(amount <= 0)
					alert("That is not a valid amount.")
				else if(authenticated_account && amount > 0)
					if(amount <= authenticated_account.money)
						playsound(src, 'sound/machines/chime.ogg', 50, 1)
						spawn_ewallet(amount,src.loc,usr)

						//create an entry in the account transaction log
						var/datum/transaction/T = new(authenticated_account.owner_name, "Credit withdrawal", -amount, machine_id)
						authenticated_account.do_transaction(T)
					else
						to_chat(usr, "\icon[src][SPAN("warning", "You don't have enough funds to do that!")]")
			if("withdrawal")
				var/amount = max(text2num(href_list["funds_amount"]),0)
				amount = round(amount, 0.01)
				if(amount <= 0)
					alert("That is not a valid amount.")
				else if(authenticated_account && amount > 0)
					if(amount <= authenticated_account.money)
						playsound(src, 'sound/machines/chime.ogg', 50, 1)
						spawn_money(amount,src.loc,usr)

						//remove the money
						var/datum/transaction/T = new(authenticated_account.owner_name, "Credit withdrawal", -amount, machine_id)
						authenticated_account.do_transaction(T)
					else
						to_chat(usr, "\icon[src][SPAN("warning", "You don't have enough funds to do that!")]")
			if("balance_statement")
				if(authenticated_account)
					var/obj/item/paper/R = new(src.loc)
					R.SetName("Account balance: [authenticated_account.owner_name]")
					R.info = "<b>NT Automated Teller Account Statement</b><br><br>"
					R.info += "<i>Account holder:</i> [authenticated_account.owner_name]<br>"
					R.info += "<i>Account number:</i> [authenticated_account.account_number]<br>"
					R.info += "<i>Balance:</i> [authenticated_account.money]cr.<br>"
					R.info += "<i>Date and time:</i> [stationtime2text()], [stationdate2text()]<br><br>"
					R.info += "<i>Service terminal ID:</i> [machine_id]<br>"

					//stamp the paper
					var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
					stampoverlay.icon_state = "paper_stamp-cent"
					if(!R.stamped)
						R.stamped = new
					R.stamped += /obj/item/stamp
					R.overlays += stampoverlay
					R.stamps += "<HR><i>This paper has been stamped by the Automatic Teller Machine.</i>"

				if(prob(50))
					playsound(loc, 'sound/items/polaroid1.ogg', 50, 1)
				else
					playsound(loc, 'sound/items/polaroid2.ogg', 50, 1)
			if ("print_transaction")
				if(authenticated_account)
					var/obj/item/paper/R = new(src.loc)
					R.SetName("Transaction logs: [authenticated_account.owner_name]")
					R.info = "<b>Transaction logs</b><br>"
					R.info += "<i>Account holder:</i> [authenticated_account.owner_name]<br>"
					R.info += "<i>Account number:</i> [authenticated_account.account_number]<br>"
					R.info += "<i>Date and time:</i> [stationtime2text()], [stationdate2text()]<br><br>"
					R.info += "<i>Service terminal ID:</i> [machine_id]<br>"
					R.info += "<table border=1 style='width:100%'>"
					R.info += "<tr>"
					R.info += "<td><b>Date</b></td>"
					R.info += "<td><b>Time</b></td>"
					R.info += "<td><b>Target</b></td>"
					R.info += "<td><b>Purpose</b></td>"
					R.info += "<td><b>Value</b></td>"
					R.info += "<td><b>Source terminal ID</b></td>"
					R.info += "</tr>"
					for(var/datum/transaction/T in authenticated_account.transaction_log)
						R.info += "<tr>"
						R.info += "<td>[T.date]</td>"
						R.info += "<td>[T.time]</td>"
						R.info += "<td>[T.target_name]</td>"
						R.info += "<td>[T.purpose]</td>"
						R.info += "<td>[T.amount]cr.</td>"
						R.info += "<td>[T.source_terminal]</td>"
						R.info += "</tr>"
					R.info += "</table>"

					//stamp the paper
					var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
					stampoverlay.icon_state = "paper_stamp-cent"
					if(!R.stamped)
						R.stamped = new
					R.stamped += /obj/item/stamp
					R.overlays += stampoverlay
					R.stamps += "<HR><i>This paper has been stamped by the Automatic Teller Machine.</i>"

				if(prob(50))
					playsound(loc, 'sound/items/polaroid1.ogg', 50, 1)
				else
					playsound(loc, 'sound/items/polaroid2.ogg', 50, 1)

			if("insert_card")
				if(!held_card)
					//this might happen if the user had the browser window open when somebody emagged it
					if(emagged > 0)
						to_chat(usr, "\icon[src] [SPAN("warning", "The ATM card reader rejected your ID because this machine has been sabotaged!")]")
					else
						var/obj/item/I = usr.get_active_hand()
						if(istype(I, /obj/item/card/id) && usr.drop(I, src))
							held_card = I
				else
					release_held_id(usr)
			if("logout")
				authenticated_account = null
				account_security_level = 0

	src.attack_hand(usr)

/obj/machinery/atm/proc/scan_user(mob/living/carbon/human/human_user as mob)
	if(!authenticated_account)
		if(human_user.wear_id)
			var/obj/item/card/id/I
			if(istype(human_user.wear_id, /obj/item/card/id) )
				I = human_user.wear_id
			else if(istype(human_user.wear_id, /obj/item/device/pda) )
				var/obj/item/device/pda/P = human_user.wear_id
				I = P.id
			if(I)
				return I

// put the currently held id on the ground or in the hand of the user
/obj/machinery/atm/proc/release_held_id(mob/living/carbon/human/human_user as mob)
	if(!held_card)
		return

	held_card.loc = src.loc
	authenticated_account = null
	account_security_level = 0

	if(ishuman(human_user))
		human_user.pick_or_drop(held_card)
	held_card = null


/obj/machinery/atm/proc/spawn_ewallet(sum, loc, mob/living/carbon/human/human_user)
	var/obj/item/spacecash/ewallet/E = new /obj/item/spacecash/ewallet(loc)
	if(ishuman(human_user))
		human_user.pick_or_drop(E, loc)
	E.worth = sum
	E.owner_name = authenticated_account.owner_name
