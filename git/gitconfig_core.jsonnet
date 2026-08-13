{
    sections: {
        core: {
            editor: "vim",
        },

        user: {
            email: "joe@lifequakesoftware.com",
            name: "Joe Castro",
        },

        init: {
	        defaultBranch: "main",
        },

        branch: {
            autoSetupMerge: "simple",
        },

        pull: {
            rebase: true,
        },

        push: {
            autoSetupRemote: true,
        },

        submodule: {
            recurse: true,
        },

        fetch: {
            recurseSubmodules: "on-demand",
        },

        'filter "lfs"': {
            clean: "git lfs clean %f",
            smudge: "git lfs smudge %f",
            required: true,
        },

        color: {
            branch: "auto",
            diff: "auto",
            status: "auto",
        },

        'color "branch"': {
            current: "yellow reverse",
            "local": "yellow",
            remote: "green",
        },

        'color "diff"': {
            meta: "blue",
            frag: "magenta",
            old: "red",
            new: "green",
        },

        'color "status"': {
            added: "yellow",
            changed: "green",
            untracked: "cyan",
        },
    }
}
