local dialogs = require 'gui.dialogs'
local choices = {}

function addCivToEmbarkList(info)
   local viewscreen = dfhack.gui.getDFViewscreen(true)

   viewscreen.start_civ:insert ('#', info.civ)
   viewscreen.start_civ_nem_num:insert ('#', info.nemeses)
   viewscreen.start_civ_entpop_num:insert ('#', info.pops)
   viewscreen.start_civ_site_num:insert ('#', info.sites)
end

function embarkAnyone()
   local viewscreen = dfhack.gui.getDFViewscreen(true)


   if viewscreen._type ~= df.viewscreen_choose_start_sitest then
      qerror("This script can only be used on the embark screen!")
   end

   for i, civ in ipairs (df.global.world.entities.all) do
      if civ.type == df.historical_entity_type.Civilization then
         local available = false

         -- Check if civ is already available to embark
         for _, item in ipairs (viewscreen.start_civ) do
            if item == civ then
               available = true
               break
            end
         end

         if not available then
            local sites = 0
            local pops = 0
            local nemeses = 0
            local histfigs = 0
            local label = ''

            -- Civs keep links to sites they no longer hold, so check owner
            -- We also take the opportunity to count population
            for j, link in ipairs(civ.site_links) do
               local site = df.global.world.world_data.sites[link.target]
               if site.civ_id == civ.id then
                  sites = sites + 1

                  -- DF stores population info as an array of groups of residents (?).
                  -- Inspecting these further could give a more accurate count.
                  for _, group in ipairs(site.populace.inhabitants) do
                     pops = pops + group.count
                  end
               end

               -- Count living nemeses
               for _, nem in ipairs (civ.nemesis_ids) do
                  if df.global.world.nemesis.all[nem].figure.died_year == -1 then
                     nemeses = nemeses + 1
                  end
               end

               -- Count living histfigs
               -- Used for death detection. May be redundant.
               for _, fig in ipairs (civ.histfig_ids) do
                  if df.global.world.history.figures[fig].died_year == -1 then
                     histfigs = histfigs + 1
                  end
               end
            end

            -- Find the civ's name, or come up with one
            if civ.name.has_name then
               label = dfhack.TranslateName(civ.name, true) .. "\n"
            else
               label = "Unnamed " ..
                  dfhack.units.getRaceReadableNameById(civ.race) ..
                  " civilisation\n"
            end

            -- Add species
            label = label .. dfhack.units.getRaceNamePluralById(civ.race) .. "\n"

            -- Add pop & site count or mark civ as dead.
            if histfigs == 0 and pops == 0 then
               label = label .. "Dead"
            else
               label = label .. "Pop: " .. (pops + nemeses) .. " Sites: " .. sites
            end

            table.insert(choices, {text = label, search_key = label:lower(),
                                   info = {civ = civ, pops = pops, sites = sites,
                                           nemeses = nemeses}})
         end
      end
   end
   dialogs.ListBox{
      frame_title = 'Embark Anyone',
      text = 'Select a civilisation to add to the list of origin civs:',
      text_pen = COLOR_WHITE,
      choices = choices,
      on_select = function(id, choice)
         addCivToEmbarkList(choice.info)
      end,
      with_filter = true,
      row_height = 4,
   }:show()
end

embarkAnyone()
