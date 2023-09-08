{
    sections: {
        'filter "lfs"': {
            clean: "git lfs clean %f",
            smudge: "git lfs smudge %f",
            required: true,
        },

        user: {
            email: "joecastr@gmail.com",
            name: "Joe Castro"
        },

        color: {
            branch: "auto",
            diff: "auto",
            status: "auto",
        },

        'color "branch"': {
            "current": "yellow reverse",
            "local": "yellow",
            "remote": "green",
        },

        'color "diff"': {
            "meta": "yellow bold",
            "frag": "magenta bold",
            "old": "red bold",
            "new": "green bold"
        },

        init: {
	        "defaultBranch": "main"
        },

        'color "status"': {
            "added": "yellow",
            "changed": "green",
            "untracked": "cyan",
        },
    }
}