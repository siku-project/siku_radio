local REQUIRED_CORE_VERSION <const> = '1.0.0'

local dependency <const> = Siku.version.checkDependency('siku_core', REQUIRED_CORE_VERSION)

if not dependency.ok then
  Siku.print.throw(dependency.message)
end

Siku.print.success(('Linked to siku_core (%s)'):format(dependency.currentVersion))
Siku.version.checkRelease('siku-project/siku_radio')

--- The modules below this file do not exist yet while it loads: the boot
--- work waits one frame so every one of them is defined.
CreateThread(function()
  Wait(0)

  RadioAccess.pushAll()

  Siku.print.success(('Radio ready, access %s, %d reserved band(s)'):format(
    AccessConfig.mode,
    #RadioBands.list()
  ))
end)
