#! /usr/bin/lua
-- 20101229 initial shape with license and all
-- 20110105 next version, functionized and nicer names
-- 20110111 writing directly to file instead of creating long string
--
-- ldap2prosody: getting data from Active Directory and write to 
-- prosody config files, for auto groupchat bookmarks and automatic 
-- buddielists (shared roster)
-- the script assumes you are using Active Directory and have (certain)
-- groups of users there who should a) be automatically included into
-- the shared roster of other members in that group, as well as b) an 
-- automatic bookmark and popup into that groups' conference room.  
-- (so far supported by the xmpp client of choice, pidgin doesn't yet)
--
-- (c) kloschi@subsignal.org 29.12.2010
--
--  ldap2prosody is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
-- 
--  ldap2prosody is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
-- 
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'lualdap'


-- CONFIG PART --

-- groups to taken care of for shared roster and groupchats
local rostergroup = { 
	'Mitarbeiter' 
}

local chatgroup = {
	'Mitarbeiter', 
	'TYPO3', 
	'Magento' 
}

-- Active Driectory Server and Credentials
local adhost = '192.168.1.xx:389'
local aduser = 'xxx'
local adpass = 'xxx'

-- Domainname of Jabberserver and Conferenceserver
local jabberdomain = 'xxxx.de'
local conf = 'conference.xxxx.de'

-- Prosody config files 
rosterfile = '/etc/prosody/groups.cfg.txt'
chatfile = '/etc/prosody/groupchats.cfg.txt'
--local rosterfile = 'groups.cfg.txt'
--local chatfile = 'groupchats.cfg.txt'

-- END CONFIG PART --

local ld = assert (lualdap.open_simple ( adhost, aduser, adpass))

function makebase (group)
	local count = 1
	local mybase = {}
	while group[count] do
		mybase[count] = 'CN=' .. group[count] .. ',OU=Gruppen,OU=xxxx,DC=xxxx,DC=de'
		count = count + 1
	end
	return mybase
end

function getusers(base, is_chat, group, outfile)
	io.output(outfile)
	local count = 1
	while base[count] do
		-- write groupheader for prosody (appended to a string)
		if is_chat then 
			io.write ('[' .. string.gsub(chatgroup[count], '^.*-', '') .. '@' .. conf .. ']\n')
		else 
			io.write ('[' .. rostergroup[count] .. ']\n')
		end
		for dn, attribs in ld:search { base = base[count], scope = 'subtree', attrs = 'member'} do
			if attribs then 
			-- here attribs holds the members of the group we looked for
				for _,v in pairs (attribs['member']) do 
					for dn2, userattribs in ld:search { base = tostring(v), scope = 'subtree' } do
						if userattribs then 
							-- iterating through groupmembers we want following values
							local user = userattribs['sAMAccountName']
							local displayname = userattribs['displayName']
							io.write (user .. '@' .. jabberdomain .. '=' .. displayname .. '\n')
		end end end end end 
		io.write('\n')
		count = count + 1 
	end
	io.output():close()
end

local mybase = makebase(chatgroup) 
getusers (mybase, 1, chatgroup, chatfile)

local mybase = makebase(rostergroup) 
getusers (mybase, nil, rostergroup, rosterfile)

