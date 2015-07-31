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

function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

function formatarValor(valor, exibirDecimal)
	if exibirDecimal == nil then
		exibirDecimal = false
	end
	local decimal = string.sub(tostring(valor),-2)
	if not exibirDecimal then
		while string.sub(tostring(decimal),-1) == "0" do
			decimal = string.sub(tostring(decimal),-2,string.len(tostring(decimal))-1)
		end
		if decimal ~= "" then
			decimal = "." .. decimal
		end
	else
		decimal = "." .. decimal
	end
	return math.floor(valor/100) .. decimal
end

function formatarPeso(valor)
	return formatarValor(valor, true) .. " oz"
end

function formatarTempo(tempo)
	local exibirTempo = " segundo"
	if tempo > 1 then
		exibirTempo = exibirTempo .. "s"
	end
	return tempo .. exibirTempo
end

function searchArrayKey(t, value)
	for k, v in pairs(t) do
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

function formatarFrase(frase, cid, msg, count, transfer)
	local player = Player(cid)
	if frase:find("|PLAYERNAME|") then
		frase = frase:gsub("|PLAYERNAME|", player:getName())
	end
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
	if frase:find("|SENHOR|") then
		local exibir = "Senhor"
		if player:getSex() == 0 then
			exibir = "Senhora"
		end
		frase = frase:gsub("|SENHOR|", exibir)
	end
	if frase:find("|MESTRE|") then
		local exibir = "Mestre"
		if player:getSex() == 0 then
			exibir = "Mestra"
		end
		frase = frase:gsub("|MESTRE|", exibir)
	end
	if frase:find("|VOCATIONNAME|") then
		frase = frase:gsub("|VOCATIONNAME|", player:getVocation():getName())
	end
	return frase
end

function formatarNomeCidade(nomeCidade)
	if nomeCidade == "Otto" then
		nomeCidade = "�tt�"
	elseif nomeCidade == "Khazad-dum" then
		nomeCidade = "Khazad-d�m"
	end
	return nomeCidade
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

function Player:withdrawMoney(amount)
	local balance = self:getBankBalance()
	if amount > balance or not self:addMoney(amount) then
		return false
	end

	self:setBankBalance(balance - amount)
	return true
end

function Player:depositMoney(amount)
	if not self:removeMoney(amount) then
		return false
	end

	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

function Player:addMoneyBank(amount)
	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

function Player:transferMoneyTo(target, amount)
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

function Player:adicionarReputacao(valor)
	self:setStorageValue(Storage.reputacao, self:pegarReputacao()+valor)
end

function Player:pegarReputacao()
	return math.max(0, self:getStorageValue(Storage.reputacao))
end

function Player:pegarRankReputacao()
	local reputacao = self:pegarReputacao()
	local rankId
	for a, b in pairs(Reputacao.ranks) do
		if b.pontos == 0 then
			rankId = a
		elseif b.pontos <= reputacao then
			rankId = a
		else
			return rankId
		end
	end
	return rankId
end

function pegarNomeRank(rankId)
	return Reputacao.ranks[rankId].nome
end

function pegarReputacaoRank(rankId)
	if Reputacao.ranks[rankId] ~= nil then
		return Reputacao.ranks[rankId].pontos
	end
	return false
end

function Player:isPromoted()
	local vocation = self:getVocation()
	local promotedVocation = vocation:getPromotion()
	promotedVocation = promotedVocation and promotedVocation:getId() or 0
	return promotedVocation == 0 and vocation:getId() ~= promotedVocation
end

function Player:promote()
	self:setVocation(Vocation(self:getVocation():getPromotion():getId()))
end

function getExpForLevel(level)
	level = level - 1
	return ((50 * level * level * level) - (150 * level * level) + (400 * level)) / 3
end

function Player:addLevel()
	self:addExperience(getExpForLevel(self:getLevel() + 1) - self:getExperience())
end

function Player:teleportarJogador(posicao, forcar, extended, direcao)
	if not self then
		return
	end

	if not extended then
		extended = false
	end

	if not forcar then
		local posicaoLivre = self:getClosestFreePosition(posicao, extended)
		if posicaoLivre.x > 0 and posicaoLivre.y > 0 then
			posicao = posicaoLivre
		end
	end

	if not direcao or not direcoes[direcao] then
		direcao = "sul"
	end

	if self:teleportTo(posicao) then
		self:setDirection(direcoes[direcao])
		Position(posicao):sendMagicEffect(efeitos["teleport"])
		return true
	end
	return false
end

function Player:curarJogador(quantidade)
	if quantidade == nil then
		quantidade = self:getMaxHealth()-self:getHealth()
	end
	self:addHealth(quantidade)
end

function Player:removerDebuffs()
	for i, v in ipairs(conditionsHealing) do
		if getCreatureCondition(self, v) == true then
			doRemoveCondition(self, v)
		end
	end
end

function removerAtributosItem(cid, item)
	local item = Item(item)
	if item:getAttribute(ITEM_ATTRIBUTE_ATTACK) then
		item:setAttribute(ITEM_ATTRIBUTE_ATTACK, 0)
	end
	if item:getAttribute(ITEM_ATTRIBUTE_DEFENSE) then
		item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, 0)
	end
	if item:getAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE) then
		item:setAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE, 0)
	end
	if item:getAttribute(ITEM_ATTRIBUTE_ARMOR) then
		item:setAttribute(ITEM_ATTRIBUTE_ARMOR, 0)
	end
	if ferramentas[item.itemid] and item:getAttribute(ITEM_ATTRIBUTE_WEIGHT) then
		local player = Player(cid)
		item:moveTo(player:getPosition())
		local itemClone = item:clone()
		item:remove()
		itemClone:setAttribute(ITEM_ATTRIBUTE_WEIGHT, ferramentas[item.itemid])
		player:addItemEx(itemClone)
	end
	return true
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function getPlayerNameById(id)
    local resultName = db.storeQuery("SELECT `name` FROM `players` WHERE `id` = " .. db.escapeString(id))
    if resultName ~= false then
        local name = result.getDataString(resultName, "name")
        result.free(resultName)
        return name
    end
    return 0
end

function Player:pegarArtigo(tipo)
	if tipo == 1 then
		return ((self:getSex() == PLAYERSEX_FEMALE) and 'a' or 'o')
	elseif tipo == 2 then
		return ((self:getSex() == PLAYERSEX_FEMALE) and 'a' or '')
	end
	return ''
end

function Player:removerOutfit(lookType)
	self:removeOutfit(lookType)
	local outfit = self:getOutfit()
	if outfit.lookType == lookType then
		local novoLookType
		if self:getSex() == PLAYERSEX_FEMALE then
			novoLookType = 136
		else
			novoLookType = 128
		end
		self:mudarOutfit(novoLookType)
		self:sendOutfitWindow()
	end
end

function Player:mudarOutfit(lookType)
	local outfit = self:getOutfit()
	self:setOutfit({lookType = lookType, lookFeet = outfit.lookFeet, lookLegs = outfit.lookLegs, lookMount = outfit.lookMount, lookHead = outfit.lookHead, lookTypeEx = outfit.lookTypeEx, lookAddons = outfit.lookAddons, lookBody = outfit.lookBody})
end

function Player:pegarOutfitLookType(outfitNome)
	local lookType = 0
	local resultId = db.storeQuery("SELECT `looktype` FROM `z_outfits` WHERE (`name` LIKE " .. db.escapeString(outfitNome) .. " OR `maleName` LIKE " .. db.escapeString(outfitNome) .. ") AND `type` LIKE " .. db.escapeString(self:getSex()))
	if resultId ~= false then
		lookType = result.getDataInt(resultId, "looktype")
		result.free(resultId)
	end
	return lookType
end

function pegarOutfitNome(lookType)
	local outfitNome = ""
	local resultId = db.storeQuery("SELECT `name` FROM `z_outfits` WHERE `looktype` LIKE " .. db.escapeString(lookType))
	if resultId ~= false then
		outfitNome = result.getDataString(resultId, "name")
		result.free(resultId)
	end
	return outfitNome
end

function pegarMontariaId(montariaNome)
	local montariaId = 0
	local resultId = db.storeQuery("SELECT `id` FROM `z_montarias` WHERE `name` LIKE " .. db.escapeString(montariaNome))
	if resultId ~= false then
		montariaId = result.getDataInt(resultId, "id")
		result.free(resultId)
	end
	return montariaId
end

function pegarMontariaNome(montariaId)
	local montariaNome = ""
	local resultId = db.storeQuery("SELECT `name` FROM `z_montarias` WHERE `id` LIKE " .. db.escapeString(montariaId))
	if resultId ~= false then
		montariaNome = result.getDataString(resultId, "name")
		result.free(resultId)
	end
	return montariaNome
end

function exibirAddon(addon, exibirArtigo)
	local exibirAddon = (exibirArtigo and "o" or "") .. (addon == 1 and "primeiro" or "segundo") .. " addon"
	if addon == 3 then
		exibirAddon = "todos os addons"
	end
	return exibirAddon
end

function exibirRecompensa(recompensa, container)
	local exibirRecompensa
	if #recompensa > 1 then
		exibirRecompensa = "1 " .. ItemType(container):getName()
	elseif #recompensa == 1 then
		exibirRecompensa = recompensa[1][2] .. " " .. ItemType(recompensa[1][1]):getName()
	end
	return exibirRecompensa
end

function Player:adicionarItensJogador(itens, container, modal)

	local sucesso = false
	local mensagem
	local pesoTotalItens = 0

	if container then
		pesoTotalItens = ItemType(container):getWeight()
	end

	for a, b in pairs(itens) do
		pesoTotalItens = pesoTotalItens + ItemType(b[1]):getWeight()
	end

	local exibirNome = exibirRecompensa(itens, container)

	if self:getFreeCapacity() >= pesoTotalItens then

		local item

		if container then
			item = Game.createItem(container, 1)
			for a, b in pairs(itens) do
				item:addItem(b[1], b[2])
			end
		else
			item = Game.createItem(itens[1][1], itens[1][2])
		end

		if self:addItemEx(item) == 0 then
			mensagem = "Voc� " .. (modal and "recebeu" or "encontrou") .. " '" .. exibirNome .. "'."
			sucesso = true
		else
			mensagem = "Voc� n�o possui espa�o para receber " .. (#itens == 1 and "o item" or "os itens") .. "."
		end
	else
		mensagem = "Voc� " .. (modal and "escolheu" or "encontrou") .. " o item '" .. exibirNome .. "' que pesa " .. pesoTotalItens .. " oz. � muito peso para voc� carregar."
	end

	return {sucesso, mensagem}
end

function Player:receberQuest(quest, storage, modal)

	local checarValor = -1
	if quest.checarValor then
		checarValor = quest.checarValor
	end

	if self:getStorageValue(storage) ~= checarValor then
		self:sendTextMessage(MESSAGE_INFO_DESCR, "Est� vazio.")
		return false
	end

	local adicionarValor = 1
	if quest.adicionarValor then
		adicionarValor = quest.adicionarValor
	end

	local recompensa
	if quest.recompensa then
		recompensa = quest.recompensa
	elseif quest.recompensaVocacao then
		local vocacao = self:getVocation():getId()
		if isInArray(Vocacoes.sorcerer, vocacao) then
			recompensa = quest.recompensaVocacao[1]
		elseif isInArray(Vocacoes.druid, vocacao) then
			recompensa = quest.recompensaVocacao[2]
		elseif isInArray(Vocacoes.paladin, vocacao) then
			recompensa = quest.recompensaVocacao[3]
		elseif isInArray(Vocacoes.knight, vocacao) then
			recompensa = quest.recompensaVocacao[4]
		end
	elseif modal then
		recompensa = quest.recompensaOpcional[modal]
	end
	local container
	if quest.container then
		container = quest.container
	elseif #recompensa > 1 then
		container = quests.containerPadrao
	end

	local adicionarItens = self:adicionarItensJogador(recompensa, container, modal)
	self:sendTextMessage(MESSAGE_INFO_DESCR, adicionarItens[2])
	if adicionarItens[1] then
		self:setStorageValue(storage, adicionarValor)
	end
end
