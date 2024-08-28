{
    // Serialize a shallow Json object as ZSH property declarations.
    manifestShellVars(value)::
        assert std.isObject(value);
        local aux(root) =
            local props = ['export %s="%s"' % [k, root.properties[k]] for k in std.objectFields(root.properties)];
            local directives = if std.objectHas(root, 'directives')
                then ['export %s=`%s`' % [k, root.directives[k]] for k in std.objectFields(root.directives)]
                else [];
            local interactive_directives = if std.objectHas(root, 'interactive_directives')
                then ['if [[ $- == *i* ]]; then'] +
                ['    export %s=`%s`' % [k, root.interactive_directives[k]] for k in std.objectFields(root.interactive_directives)] +
                ['fi']
                else [];
            local aliases = if std.objectHas(root, 'aliases')
                then ["alias %s='%s'" % [k, root.aliases[k]] for k in std.objectFields(root.aliases)]
                else [];
            std.lines(std.flattenArrays([[
                '#! /bin/bash',
                '',
                '#pragma watermark',
                '',
                '#pragma once',
                ''],
                props, directives, interactive_directives, aliases]));
        aux(value)
}