local io = require 'io'
local os = require 'os'

local log = {}

log.levels = {
    fatal = 0,
    ['error'] = 1,
    warning = 2,
    info = 3,
    debug = 4
}

-- Terminal colors!!
log.colors = {
    default = 0,

    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37
}

function log.configure(opt)
    log.level = opt.level or log.level or 1
    log.stderr = opt.stderr or log.stderr or true
    log.vbuf = opt.vbuf or log.vbuf or 'line'
    log.setIndent(opt.indent or log.indent or 0)

    log.filename = opt.filename
    log.file = opt.file
    assert(not(log.file and log.filename),
        "need either a filename or a file handle, not both")

    if log.filename then
        local err
        log.file, err = io.open(log.filename, 'w')
        if not log.file then
            print(string.format('log: failed to open %s: %s', log.filename, err))
            return
        end
        log.file:setvbuf(log.vbuf)
    end

    if log.file then
        if log.stderr then
            log._write = log._writeToFileAndStderr
        else
            log._write = log._writeToFile
        end
    else
        if log.stderr then
            log._write = log._writeToStderr
        else
            -- for disabling logging altogether
            log._write = function() end
        end
    end
end

function log.close()
    if log.file then
        log.file:close()
    end
end

local writeLineInternal = function(file, fmt, ...)
    file:write(fmt:format(...))
    file:write('\n')
    file:flush()
end

local writeInternal = function(file, fmt, ...)
    file:write(fmt:format(...))
end

function log._writeToFile(msg, ...)
    writeLineInternal(log.file, msg, ...)
end

function log._writeToStderr(msg, ...)
    writeLineInternal(io.stderr, msg, ...)
end

function log._writeToFileAndStderr(msg, ...)
    writeLineInternal(io.stderr, msg, ...)
    writeLineInternal(log.file, msg, ...)
end


function log.fatal(msg, ...)
    if log.level >= log.levels.fatal then
        log._write('F '..log.indentString..msg, ...)
    end
end

function log.error(msg, ...)
    if log.level >= log.levels.error then
        log._write('E '..log.indentString..msg, ...)
    end
end

function log.warning(msg, ...)
    if log.level >= log.levels.warning then
        log._write('W '..log.indentString..msg, ...)
    end
end

function log.info(msg, ...)
    if log.level >= log.levels.info then
        log._write('I '..log.indentString..msg, ...)
    end
end

function log.debug(msg, ...)
    if log.level >= log.levels.debug then
        log._write('D '..log.indentString..msg, ...)
    end
end

function log.setIndent(n)
    if n ~= log.indent then
        log.indentString = string.rep(' ', n)
        log.indent = n
    end
end

function log.setColor(colorName)
    local code = log.colors[colorName] or log.colors.default
    local fmt = string.char(0x1b)..'[%sm'
    if log.stderr then
        writeInternal(io.stderr, fmt, code)
    end
    if log.file then
        writeInternal(log.file, fmt, code)
    end
end

return log
