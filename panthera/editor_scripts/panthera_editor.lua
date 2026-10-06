---@diagnostic disable
-- Panthera 2.0 Editor for the Defold editor commands. A file goes to the running editor through its port; when the
-- editor is not running, it starts with the file. The editor is installed once from the latest GitHub release into a
-- folder shared by all projects; the installed release is kept in the global Defold preferences.
local M = {}

local TITLE = "Panthera Editor"
local SUBTITLE = "Animation editor for Defold"
local ICON = "/panthera/editor_scripts/panthera_editor_icon.png"
local DIALOG_WIDTH = 480
-- The editor listens here (socket_listener.lua in the editor)
local EDITOR_URL = "http://localhost:16114/"
local RELEASES_URL = "https://api.github.com/repos/Insality/panthera/releases?per_page=30"
local RELEASE_TAG = "^editor%.%d+$"
local TAG_PREF = "panthera.editor_tag"
local APP_PREF = "panthera.editor_app"
-- Downloading to a file (http.request with path) came in Defold 1.13.1
local DEFOLD_SINCE = "1.13.1"
local QUIET = { reload_resources = false, out = "discard", err = "discard" }
local CAPTURE = { reload_resources = false, out = "capture", err = "discard" }

local MACOS = { system = "macos", asset = "_release_macos.app.dmg", home = "HOME", folder = "/Library/Application Support/Panthera Editor" }
local PLATFORMS = {
	["arm64-macos"] = MACOS,
	["x86_64-macos"] = MACOS,
	["x86_64-win32"] = { system = "win32", asset = "_release_windows.zip", binary = "Panthera20.exe", home = "LOCALAPPDATA", folder = "\\Panthera Editor" },
	["x86_64-linux"] = { system = "linux", asset = "_release_linux.zip", binary = "Panthera20.x86_64", home = "HOME", folder = "/.local/share/panthera-editor" },
	["arm64-linux"] = { system = "linux", asset = "_release_linux_arm.zip", binary = "Panthera20.arm64", home = "HOME", folder = "/.local/share/panthera-editor" },
}

local installing = false


function M.get_prefs_schema()
	return {
		[TAG_PREF] = editor.prefs.schema.string({ scope = editor.prefs.SCOPE.GLOBAL }),
		[APP_PREF] = editor.prefs.schema.string({ scope = editor.prefs.SCOPE.GLOBAL }),
	}
end


---Sends the command to the running editor or starts the editor with it. A problem is told in a dialog.
---@param command string|nil "open" or "create"; nil only starts the editor
---@param path string|nil absolute path of the file for the command
function M.run(command, path)
	M._guarded(M._run, command, path)
end


---Installs the latest editor release, if it is not installed yet
function M.update()
	M._guarded(M._update)
end


function M._run(command, path)
	if not M._send(command, path) then
		M._start(command, path)
	end
end


---@return boolean is_sent false when the editor is not running
function M._send(command, path)
	local body = json.encode({ command = command, path = path })
	return pcall(http.request, EDITOR_URL, { method = "POST", body = body })
end


function M._start(command, path)
	local app = M._installed_app() or M._install_latest()
	if app then
		M._launch(app, M._arguments(command, path))
	end
end


function M._update()
	local release = M._latest_release()
	if release.tag == editor.prefs.get(TAG_PREF) and M._installed_app() then
		M._tell(TITLE .. " is up to date", "Installed " .. M._version(release.tag) .. ", the latest release.")
	elseif M._ask_download(release) then
		M._install(release)
		M._tell("Updated to " .. M._version(release.tag), "Restart " .. TITLE .. " if it is running.")
	end
end


---@return string|nil app nil when the editor is not installed
function M._installed_app()
	local app = editor.prefs.get(APP_PREF)
	if app ~= "" and editor.external_file_attributes(app).exists then
		return app
	end
	return nil
end


---@return string|nil app nil when the download was declined
function M._install_latest()
	local release = M._latest_release()
	if M._ask_download(release) then
		return M._install(release)
	end
	return nil
end


---@return { tag:string, asset:{ name:string, url:string, size:number, sha256:string } }
function M._latest_release()
	local response = http.request(RELEASES_URL, { as = "json" })
	assert(response.status == 200, "GitHub releases answered " .. tostring(response.status))
	for _, release in ipairs(response.body) do
		if release.tag_name:match(RELEASE_TAG) and not release.draft and not release.prerelease then
			return { tag = release.tag_name, asset = M._release_asset(release) }
		end
	end
	error("there is no " .. TITLE .. " release on GitHub", 0)
end


function M._release_asset(release)
	local suffix = M._platform().asset
	for _, asset in ipairs(release.assets) do
		if asset.name:sub(-#suffix) == suffix then
			return { name = asset.name, url = asset.browser_download_url, size = asset.size, sha256 = asset.digest:match("^sha256:(%x+)$") }
		end
	end
	error(release.tag_name .. " has no build for " .. editor.platform, 0)
end


-- An editor already installed is updated, otherwise it is installed for the first time
function M._ask_download(release)
	local megabytes = math.floor(release.asset.size / 1048576 + 0.5)
	local source = "Download " .. megabytes .. " MB from github.com/Insality/panthera"
	local installed = M._installed_app() and editor.prefs.get(TAG_PREF)
	if installed then
		return M._ask("Update to " .. M._version(release.tag) .. "?", source .. ". Installed " .. M._version(installed) .. ".", "Update")
	end
	return M._ask("Install " .. TITLE .. " " .. M._version(release.tag) .. "?", source .. " once, for all projects on this computer.\n\nInstall folder: " .. M._root(), "Install")
end


-- Download and unpacking take a while: a command run again meanwhile is told to wait.
---@return string app
function M._install(release)
	assert(not installing, TITLE .. " is still being installed, see the console.")
	installing = true
	local installed, app = pcall(M._install_release, release)
	installing = false
	assert(installed, TITLE .. " " .. release.tag .. " is not installed: " .. tostring(app))
	return app
end


-- The preferences are written last: an install stopped midway is done again from the start.
function M._install_release(release)
	M._check_defold()
	local folder = M._join(M._root(), release.tag)
	local archive = M._join(folder, release.asset.name)
	M._download(release.asset, archive)
	print(TITLE .. ": unpacking to " .. folder)
	local app = M._unpack(archive, folder)
	M._remove(archive)
	editor.prefs.set(TAG_PREF, release.tag)
	editor.prefs.set(APP_PREF, app)
	print(TITLE .. ": " .. release.tag .. " is installed")
	return app
end


function M._check_defold()
	assert(M._at_least(editor.version, DEFOLD_SINCE), TITLE .. " install needs Defold " .. DEFOLD_SINCE .. " or newer, this is " .. tostring(editor.version) .. ".")
end


---@param version string
---@param least string
---@return boolean
function M._at_least(version, least)
	local have, need = {}, {}
	for number in tostring(version):gmatch("%d+") do
		table.insert(have, tonumber(number))
	end
	for number in least:gmatch("%d+") do
		table.insert(need, tonumber(number))
	end
	for index = 1, #need do
		if (have[index] or 0) ~= need[index] then
			return (have[index] or 0) > need[index]
		end
	end
	return true
end


-- http.request with path makes the missing folders itself
function M._download(asset, archive)
	print(TITLE .. ": downloading " .. asset.url)
	local response = http.request(asset.url, { path = archive })
	assert(response.status >= 200 and response.status < 300, "the download answered " .. tostring(response.status))
	assert(M._sha256(archive) == asset.sha256, "the download is damaged or incomplete, try again")
end


-- Tools every system has: the editor has no hashing of its own
function M._sha256(path)
	local system = M._platform().system
	if system == "win32" then
		local output = editor.execute("certutil.exe", "-hashfile", path, "SHA256", CAPTURE)
		for line in output:gmatch("[^\r\n]+") do
			local hex = line:gsub("%s", "")
			if #hex == 64 and hex:match("^%x+$") then
				return hex:lower()
			end
		end
		return nil
	end
	local output = system == "macos" and editor.execute("/usr/bin/shasum", "-a", "256", path, CAPTURE) or editor.execute("sha256sum", path, CAPTURE)
	return output:match("^(%x+)%s"):lower()
end


-- The macOS build is an .app inside a disk image; ditto keeps its symlinks and permissions.
-- The zip builds hold one folder named as the archive, next to the macOS metadata which is skipped.
---@return string app the .app on macOS, the executable elsewhere
function M._unpack(archive, folder)
	local platform = M._platform()
	if platform.system == "macos" then
		local app = M._join(folder, M._file_name(archive):gsub("%.dmg$", ""))
		local mount = M._join(folder, "mount")
		editor.execute("/usr/bin/hdiutil", "attach", archive, "-nobrowse", "-readonly", "-noautoopen", "-mountpoint", mount, QUIET)
		local copied, problem = pcall(editor.execute, "/usr/bin/ditto", M._join(mount, M._file_name(app)), app, QUIET)
		editor.execute("/usr/bin/hdiutil", "detach", mount, "-force", QUIET)
		assert(copied, problem)
		return app
	end

	local content = M._file_name(archive):gsub("%.zip$", "")
	zip.unpack(archive, folder, { on_conflict = zip.ON_CONFLICT.OVERWRITE }, { content })
	local binary = M._join(folder, content .. "/" .. platform.binary)
	if platform.system == "linux" then
		-- zip.unpack does not keep the executable flag
		editor.execute("chmod", "+x", binary, QUIET)
	end
	return binary
end


function M._launch(app, arguments)
	local command = M._launcher(app)
	for index = 1, #arguments do
		table.insert(command, arguments[index])
	end
	-- Given any argument, the engine stops finding its project by itself: it takes the last one ending in .projectc
	table.insert(command, M._project_file(app))
	table.insert(command, QUIET)
	print(TITLE .. ": starting " .. app)
	editor.execute(table.unpack(command))
end


-- Defold waits for the command to exit: the editor is started by a launcher that returns at once
---@return string[] command the editor arguments follow it
function M._launcher(app)
	local system = M._platform().system
	if system == "macos" then
		return { "/usr/bin/open", app, "--args" }
	end
	if system == "win32" then
		return { "cmd.exe", "/c", "start", "", "/D", M._parent(app), app }
	end
	return { "sh", "-c", 'cd "$(dirname "$0")" && nohup "$0" "$@" >/dev/null 2>&1 &', app }
end


function M._project_file(app)
	if M._platform().system == "macos" then
		return M._join(app, "Contents/Resources/game.projectc")
	end
	return M._join(M._parent(app), "game.projectc")
end


---@return string[]
function M._arguments(command, path)
	if command then
		return { "--" .. command .. "=" .. path }
	end
	return {}
end


function M._remove(path)
	if M._platform().system == "win32" then
		editor.execute("cmd.exe", "/c", "del", "/f", "/q", path, QUIET)
	else
		editor.execute("rm", "-f", path, QUIET)
	end
end


function M._platform()
	local platform = PLATFORMS[editor.platform]
	assert(platform, TITLE .. " has no build for " .. tostring(editor.platform) .. ".")
	return platform
end


---@return string
function M._root()
	local platform = M._platform()
	return os.getenv(platform.home) .. platform.folder
end


function M._guarded(action, ...)
	local done, problem = pcall(action, ...)
	if not done then
		M._tell("Something went wrong", tostring(problem))
	end
end


function M._tell(message, details)
	print(TITLE .. ": " .. message .. ". " .. details)
	local close = editor.ui.dialog_button({ text = "Close", default = true, cancel = true })
	M._show_dialog(message, details, { close })
end


---@return boolean is_accepted
function M._ask(message, details, action)
	local cancel = editor.ui.dialog_button({ text = "Cancel", cancel = true, result = false })
	local accept = editor.ui.dialog_button({ text = action, default = true, result = true })
	return M._show_dialog(message, details, { cancel, accept }) == true
end


-- Every dialog has the Panthera icon and name on top, then the message with its details
function M._show_dialog(message, details, buttons)
	-- The dialog pads its header itself
	local header = editor.ui.horizontal({
		padding = editor.ui.PADDING.NONE,
		spacing = editor.ui.SPACING.LARGE,
		alignment = editor.ui.ALIGNMENT.LEFT,
		children = {
			editor.ui.image({ image = ICON, width = 96, height = 96 }),
			editor.ui.vertical({
				alignment = editor.ui.ALIGNMENT.LEFT,
				spacing = editor.ui.SPACING.SMALL,
				grow = true,
				children = {
					editor.ui.heading({ text = TITLE, style = editor.ui.HEADING_STYLE.H2 }),
					editor.ui.heading({ text = SUBTITLE, style = editor.ui.HEADING_STYLE.H5, color = editor.ui.COLOR.HINT }),
				}
			}),
		}
	})
	local content = editor.ui.vertical({
		padding = editor.ui.PADDING.LARGE,
		children = {
			editor.ui.heading({ text = message, style = editor.ui.HEADING_STYLE.H5 }),
			editor.ui.paragraph({ text = details, color = editor.ui.COLOR.HINT }),
		}
	})
	local dialog = editor.ui.dialog({ title = TITLE, header = header, content = content, buttons = buttons, width = DIALOG_WIDTH })
	return editor.ui.show_dialog(dialog)
end


-- Releases are tagged "editor.1254", the editor names itself "v1254"
function M._version(tag)
	return "v" .. tag:match("%d+$")
end


-- Paths go to the platform's programs as they are, so they take its separator
function M._join(base, relative)
	local separator = editor.platform == "x86_64-win32" and "\\" or "/"
	return base .. separator .. relative:gsub("/", separator)
end


function M._file_name(path)
	return path:match("([^/\\]+)$")
end


function M._parent(path)
	return path:match("^(.*)[/\\][^/\\]+$")
end


return M
