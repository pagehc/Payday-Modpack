local Menu = BeardLib.Items.Menu
local align_methods = {
    grid = "AlignItemsGrid",
    normal = "AlignItemsNormal",
    reversed = "AlignItemsReversed",
    reversed_grid = "AlignItemsReversedGrid",
    centered_grid = "AlignItemsCenteredGrid",
    reversed_centered_grid = "AlignItemsReversedCenteredGrid"
}

function Menu:AlignItems(menus, no_parent)
	if menus then
		for _, item in pairs(self._my_items) do
			if item.menu_type then
				item:AlignItems(true, true)
			end
		end
	end
    if self.align_method and align_methods[self.align_method] then
        self[align_methods[self.align_method]](self)
    else
        self:AlignItemsNormal()
    end
    if self.parent.AlignItems and not no_parent then
		self.parent:AlignItems()
	else
		self:CheckItems()
    end
end

function Menu:AlignItemsPost(max_h, prev_item)
	local additional = (self.last_y_offset or (prev_item and prev_item:Offset()[2] or 0))
	max_h = max_h + additional -- self:TextHeight() + additional
	self:UpdateCanvas(max_h)
end

function Menu:RepositionItem(item, last_positioned_item, prev_item, max_h)
	local repos = item:Reposition(last_positioned_item, prev_item)
	if repos then
		last_positioned_item = item
	end
	local count = not repos or item.count_as_aligned
	if count then
		prev_item = item
	end
	if max_h and count or item.count_height then
		max_h = math.max(max_h, item:Panel():bottom())
	end
	return last_positioned_item, prev_item, max_h
end

function Menu:AlignItemsNormal()
    if not self:alive() then
        return
    end
    local max_h = 0
    local prev_item
    local last_positioned_item
	for _, item in pairs(self._my_items) do
		if item.visible and item:alive() then
			if not item.ignore_align then
				local offset = item:Offset()
				local panel = item:Panel()
				panel:set_x(offset[1])
				if alive(prev_item) then
					panel:set_world_y(prev_item:Panel():world_bottom() + offset[2])
				else
					panel:set_y(offset[2])
				end
			end
			last_positioned_item, prev_item, max_h = self:RepositionItem(item, last_positioned_item, prev_item, max_h)
		end
	end
    self:AlignItemsPost(max_h, prev_item)
end

function Menu:AlignItemsReversed()
    if not self:alive() then
        return
    end
    local max_h = 0
    local prev_item
    local last_positioned_item
    for i=#self._my_items, 1, -1 do
		local item = self._my_items[i]
		if item.visible and item:alive() then
			if not item.ignore_align then
				local panel = item:Panel()
				local offset = item:Offset()
				panel:set_x(offset[1])
				if alive(prev_item) then
					panel:set_world_y(prev_item:Panel():world_bottom() + offset[2])
				else
					panel:set_y(offset[2])
				end
			end
            last_positioned_item, prev_item, max_h = self:RepositionItem(item, last_positioned_item, prev_item, max_h)
        end
    end
    self:AlignItemsPost(max_h, prev_item)
end

function Menu:AlignItemsGrid()
    if not self:alive() then
        return
    end
    local prev_item
    local last_positioned_item
    local max_h = 0
    local max_x = 0
    local max_y = 0
    local items_w = self:ItemsWidth()
    for _, item in pairs(self._my_items) do
		if item.visible and item:alive() then
			local panel = item:Panel()
			if not item.ignore_align then
				local offset = item:Offset()
				if panel:w() + (max_x + offset[1]) - items_w > 0.001 then
					max_y = max_h
					max_x = 0
				end
				panel:set_position(max_x + offset[1], max_y + offset[2])
			end
			local repos = item:Reposition(last_positioned_item, prev_item)
            if repos then
                last_positioned_item = item
            end
            local was_aligned = not repos or item.count_as_aligned
			if was_aligned then
				prev_item = item
				max_x = math.max(max_x, panel:right())
			end
            if was_aligned or item.count_height then
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end    
    self:AlignItemsPost(max_h, prev_item)
end

function Menu:AlignItemsCenteredGrid()
    if not self:alive() then
        return
    end
    local prev_item
    local last_positioned_item
    local max_h = 0
    local max_x = 0
    local max_y = 0
    local items_w = self:ItemsWidth()
    local center = items_w / 2
    local current_row = {}
    local function centerify_row()
        if #current_row == 0 then return end
        local centerify = center - (max_x / 2)
        for _, row_item in pairs(current_row) do
            if not row_item.repos then
                row_item.panel:move(centerify)
            end
        end
        current_row = {}
    end
    for _, item in pairs(self._my_items) do
		if item.visible and item:alive() then
			local panel = item:Panel()
			if not item.ignore_align then
				local offset = item:Offset()
				if panel:w() + (max_x + offset[1]) - items_w > 0.001 then
					centerify_row()
					max_y = max_h
					max_x = 0
				end
				panel:set_position(max_x + offset[1], max_y + offset[2])
			end
			local repos = item:Reposition(last_positioned_item, prev_item)
            if repos then
                last_positioned_item = item
            end
            local was_aligned = not repos or item.count_as_aligned
            if was_aligned or item.count_height then
                if was_aligned then
                    prev_item = item
                    max_x = math.max(max_x, panel:right())
                end
                table.insert(current_row, {panel = panel, repos = repos})
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end
    centerify_row()
    self:AlignItemsPost(max_h, prev_item)
end

function Menu:AlignItemsReversedCenteredGrid()
    if not self:alive() then
        return
    end
    local prev_item
    local last_positioned_item
    local max_h = 0
    local max_x = 0
    local max_y = 0
    local items_w = self:ItemsWidth()
    local center = items_w / 2
    local current_row = {}
    local function centerify_row()
        if #current_row == 0 then return end
        local centerify = center - (max_x / 2)
        for _, row_item in pairs(current_row) do
            if not row_item.repos then
                row_item.panel:move(centerify)
            end
        end
        current_row = {}
    end
    for i=#self._my_items, 1, -1 do
        local item = self._my_items[i]
		if item.visible and item:alive() then
			local panel = item:Panel()
			if not item.ignore_align then
				local offset = item:Offset()
				if panel:w() + (max_x + offset[1]) - items_w > 0.001 then
					centerify_row()
					max_y = max_h
					max_x = 0
				end
				panel:set_position(max_x + offset[1], max_y + offset[2])
			end
			local repos = item:Reposition(last_positioned_item, prev_item)
            if repos then
                last_positioned_item = item
            end
			local was_aligned = not repos or item.count_as_aligned
            if was_aligned or item.count_height then
                if was_aligned then
                    prev_item = item
                    max_x = math.max(max_x, panel:right())
                end
                table.insert(current_row, {panel = panel, repos = repos})
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end
    centerify_row()
    self:AlignItemsPost(max_h, prev_item)
end

function Menu:AlignItemsReversedGrid()
    if not self:alive() then
        return
    end
    local prev_item
    local last_positioned_item
    local max_h = 0
    local max_x = 0
    local max_y = 0
    for i=#self._my_items, 1, -1 do
        local item = self._my_items[i]
		if item.visible and item:alive() then
			local panel = item:Panel()
			if not item.ignore_align then
				local offset = item:Offset()
				if panel:w() + (max_x + offset[1]) - self:ItemsWidth() > 0.001 then
					max_y = max_h
					max_x = 0
				end
				panel:set_position(max_x + offset[1], max_y + offset[2])
			end
			local repos = item:Reposition(last_positioned_item, prev_item)
            if repos then
                last_positioned_item = item
            end
			if not repos or item.count_as_aligned then
                prev_item = item
                max_x = math.max(max_x, panel:right())
            end
            if (not repos or item.count_as_aligned or item.count_height) then
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end    
    self:AlignItemsPost(max_h, prev_item)
end