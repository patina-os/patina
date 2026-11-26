# patina: fastfetch greets every new kitty window instead of fish's own greeting, and
# starship, zoxide (z) and atuin's history search (Ctrl+R) are on. Written by
# `patina theme set` while this first line stays; remove it to keep your own.
if status is-interactive
    if set -q KITTY_WINDOW_ID; and command -q fastfetch
        function fish_greeting
            fastfetch
        end
    end
    command -q starship; and starship init fish | source
    command -q zoxide; and zoxide init fish | source
    command -q atuin; and atuin init fish --disable-up-arrow | source
end
