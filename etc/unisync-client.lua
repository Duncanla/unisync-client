--
-- Unisync global lsyncd configuration
-- 
-- Copyright (c) 2012, Luke Duncan <Duncan72187@gamil.com>
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public license version 2 as
-- published by the Free Software Foundation. See COPYING for more details.
--

unisync_dir = os.getenv("HOME") .. "/.unisync"

settings = {
   logfile = unisync_dir .. "/lsyncd.log",
   statusFile = unisync_dir .. "/lsyncd.status",
   nodaemon = true,
   maxProcesses = 1
}

client_update = {
   delay = 5,

   action = function(inlet)
               local elist = inlet.getEvents()
               local config = inlet.getConfig()
               local paths = elist.getPaths()
               
               --remove leading / from paths for unison
               local unisonPaths = {}
               for _, pathStr in ipairs(paths) do
                  local path = string.sub(pathStr, 2)
                  table.insert(unisonPaths, path) 
               end

               -- Format path options for unison
               local pathsOpt = "-path " .. table.concat(unisonPaths," -path ")
               log("Normal", "Local files changed. Syncing...\n", paths)
               
               -- Remove trailing / from source for consistency
               local sourceOpt = config.source
               if ( string.sub(sourceOpt, -1) == "/") then
                  sourceOpt = string.sub(sourceOpt, 1, -2)
               end


               spawnShell(elist,
                          "unisync-client-sync $1 $2 $3 $4 $5 $6",
                          config.targethost, config.targetport,
                          sourceOpt,
                          config.target,
                          pathsOpt,
                          table.concat(config.unisonOpts, " ") )
            end,
   
   init = function(event)
             local inlet = event.inlet;
             local config = inlet.getConfig()
             
             -- converter excludes to unison ignore statements
             local unisonIgnores = {}
             local excludes = inlet.getExcludes()
             for _, excludeStr in ipairs(excludes) do
                local ignore = excludeStr
                ignore = string.gsub(ignore, "%.", "\\.")
                ignore = string.gsub(ignore, "%^", "\\^")
                ignore = string.gsub(ignore, "%$", "\\$")
                ignore = string.gsub(ignore, "%+", "\\+")
                ignore = string.gsub(ignore, "%|", "\\|")
                ignore = string.gsub(ignore, "%{", "\\{")
                ignore = string.gsub(ignore, "%}", "\\}")
                ignore = string.gsub(ignore, "%(", "\\(")
                ignore = string.gsub(ignore, "%)", "\\)")
                ignore = string.gsub(ignore, "?", "[^/]")
                ignore = string.gsub(ignore, "%*", "[^/]*")
                -- fix occurances of ** which we just expanded incorrectly
                ignore = string.gsub(ignore, '%[%^/%]%*%[%^/%]%*', '.*')
                -- handle slashes at the beginning and end of the exclude
                if (string.sub(excludeStr, 1, 1) == "/" and
                 string.sub(ignore,-1) == "/") then 
                   ignore = string.gsub(ignore,"/(.*)/","^%1$")
                else
                   ignore = string.gsub(ignore,"^/(.*)","^%1(/.*)*")
                   ignore = string.gsub(ignore,"(.*)/$","^(.*/)*%1$")
                end

                ignore = "Regex " .. ignore
                -- add some quotes to escape the regexp
                ignore = "\"" .. ignore .. "\""
                table.insert(unisonIgnores, ignore)
             end
             
             local ignoreS = table.concat(unisonIgnores, '\n')
             log("Normal", "Converted excludes to unison ignores\n",
                 table.concat(excludes,"\n"), "\n------>\n", ignoreS)
             
             local ignoreOpt = "-ignore " .. table.concat(unisonIgnores,
                                                    " -ignore ");

             -- Remove trailing / from source for consistency
             local sourceOpt = config.source
             if ( string.sub(sourceOpt, -1) == "/") then
                sourceOpt = string.sub(sourceOpt, 1, -2)
             end

             spawnShell(event,
                        "unisync-client-syncinit $1 $2 $3 $4 $5 $6",
                        config.targethost,
                        config.targetport,
                        sourceOpt,
                        config.target,
                        ignoreOpt,
                        config.unisonOpts)

          end,
   
}

dofile(unisync_dir .. "/unisync-client.lua")