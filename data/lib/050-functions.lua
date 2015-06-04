function capAll(str)
	local strLimpa = str
	local b = string.gmatch(str, "(.*) %[")
	for a in b do
		b = string.gmatch(a, "(.*) %[")
		strLimpa = a
	end
	for a in b do
		strLimpa = a
	end
	local novaStr = ""; palavraSeparada = string.gmatch(strLimpa, "([^%s]+)")
	for v in palavraSeparada do
		v = v:gsub("^%l", string.upper)
		if novaStr ~= "" then
			novaStr = novaStr.." "..v
		else
			novaStr = v
		end
	end
	local formatar = {
		{"Of", "of"}
	}
	for a, b in pairs(formatar) do
		novaStr = novaStr:gsub(b[1], b[2])
	end
	novaStr = str:gsub(strLimpa, novaStr)
	return novaStr
end

function formatarValor(valor)
	local decimal = string.sub(tostring(valor),-2)
	while string.sub(tostring(decimal),-1) == "0" do
		decimal = string.sub(tostring(decimal),-2,string.len(tostring(decimal))-1)
	end
	if decimal ~= "" then
		decimal = "."..decimal
	end
	return math.floor(valor/100)..decimal
end

function searchArrayKey(t, value)
	for k,v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)
	return keys
end

function getFluidNameByType(type)
	if fluids[type] ~= nil then
		return fluids[type].name
	end
	return nil
end

function formatarFraseNpc(frase, cid, msg, count, transfer)
	local player = Player(cid)
	if frase:find("|PLAYERBALANCE|") then
		frase = frase:gsub("|PLAYERBALANCE|", player:getBankBalance())
	end
	if frase:find("|PLAYERMONEY|") then
		frase = frase:gsub("|PLAYERMONEY|", player:getMoney())
	end
	if frase:find("|MONEYCOUNT|") then
		frase = frase:gsub("|MONEYCOUNT|", getMoneyCount(msg))
	end
	if frase:find("|MONEYCOUNT100|") then
		frase = frase:gsub("|MONEYCOUNT100|", getMoneyCount(msg)*100)
	end
	if frase:find("|SHOWCOUNT|") then
		frase = frase:gsub("|SHOWCOUNT|", count)
	end
	if frase:find("|SHOWTRANSFER|") then
		frase = frase:gsub("|SHOWTRANSFER|", transfer)
	end
	return frase
end

function playerExists(name)
	local resultId = db.storeQuery('SELECT `name` FROM `players` WHERE `name` = ' .. db.escapeString(name))
	if resultId then
		result.free(resultId)
		return true
	end
	return false
end

function isValidMoney(money)
	return tonumber(money) ~= nil and money > 0 and money < 4294967296
end

function getMoneyCount(string)
	local b, e = string:find("%d+")
	local money = b and e and tonumber(string:sub(b, e)) or -1
	if isValidMoney(money) then
		return money
	end
	return -1
end

function getMoneyWeight(money)
	local gold = money
	local crystal = math.floor(gold / 10000)
	gold = gold - crystal * 10000
	local platinum = math.floor(gold / 100)
	gold = gold - platinum * 100
	return (ItemType(2160):getWeight() * crystal) + (ItemType(2152):getWeight() * platinum) + (ItemType(2148):getWeight() * gold)
end

function Player.withdrawMoney(self, amount)
	local balance = self:getBankBalance()
	if amount > balance or not self:addMoney(amount) then
		return false
	end

	self:setBankBalance(balance - amount)
	return true
end

function Player.depositMoney(self, amount)
	if not self:removeMoney(amount) then
		return false
	end

	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

function Player.transferMoneyTo(self, target, amount)
	local balance = self:getBankBalance()
	if amount > balance then
		return false
	end

	local targetPlayer = Player(target)
	if targetPlayer then
		targetPlayer:setBankBalance(targetPlayer:getBankBalance() + amount)
	else
		if not playerExists(target) then
			return false
		end
		db.query("UPDATE `players` SET `balance` = `balance` + '" .. amount .. "' WHERE `name` = " .. db.escapeString(target))
	end

	self:setBankBalance(self:getBankBalance() - amount)
	return true
end

function isWalkable(pos, creature, proj, pz)
	if getTileThingByPos({x = pos.x, y = pos.y, z = pos.z, stackpos = 0}).itemid == 0 then return false end
	if getTopCreature(pos).uid > 0 and creature then return false end
	if getTileInfo(pos).protection and pz then return false, true end
	local n = not proj and 3 or 2
	for i = 0, 255 do
		pos.stackpos = i
		local tile = getTileThingByPos(pos)
		if tile.itemid ~= 0 and not isCreature(tile.uid) then
			if hasProperty(tile.uid, n) or hasProperty(tile.uid, 7) then
				return false
			end
		end
	end
	return true
end

function Player.setReputacao(self, valor)
	self:setStorageValue(Storage.reputacao, self:getReputacao()+valor)
end

function Player.getReputacao(self)
	return math.max(0, self:getStorageValue(Storage.reputacao))
end