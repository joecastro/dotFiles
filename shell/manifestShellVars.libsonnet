{
    // Serialize a shallow Json object as ZSH property declarations.
    manifestShellVars(value)::
        local aux(root) =
            if !std.isObject(root) then
                error 'Expected a object, got %s' % std.type(value)
            else
                local props = ['export %s="%s"' % [k, root.properties[k]] for k in std.objectFields(root.properties)];
                local directives = if std.objectHas(root, 'directives')
                    then ['export %s=`%s`' % [k, root.directives[k]] for k in std.objectFields(root.directives)]
                    else [];
                local aliases = if std.objectHas(root, 'aliases')
                    then ["alias %s='%s'" % [k, root.aliases[k]] for k in std.objectFields(root.aliases)]
                    else [];
                std.lines(['#! /bin/bash', '', '#pragma watermark', '', '#pragma once', ''] + props + directives + aliases);
        aux(value)
}