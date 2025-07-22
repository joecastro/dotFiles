{
    sections: {
        core: {
            editor: "vim"
        },

        user: {
            email: "joecastr@gmail.com",
            name: "Joe Castro"
        },

        init: {
	        defaultBranch: "main"
        },

        pull: {
            rebase: true
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
            new: "green"
        },

        'color "status"': {
            added: "yellow",
            changed: "green",
            untracked: "cyan",
        },
    }
}