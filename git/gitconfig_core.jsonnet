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
            meta: "yellow bold",
            frag: "magenta bold",
            old: "red bold",
            new: "green bold"
        },

        'color "status"': {
            added: "yellow",
            changed: "green",
            untracked: "cyan",
        },
    }
}