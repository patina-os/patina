# patina: fastfetch greets every new kitty window instead of fish's own greeting. Written
# by `patina theme set` while this first line stays; remove it to keep your own.
if status is-interactive; and set -q KITTY_WINDOW_ID; and command -q fastfetch
    function fish_greeting
        fastfetch
    end
end
