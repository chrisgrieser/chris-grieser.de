#!/usr/bin/env zsh
# INFO
# - Checks the deployment status of the latest GitHub Action run and exits
#   either after a timeout or when done.
# - Requires a `$GITHUB_TOKEN`, due to the high number of request being sent.
# - The json response from GitHub is parsed via `cut` and `grep` instead of
#   `jq`/`yq` to avoid introducing a dependency.
# - If on macOS, plays a sound when done.
#───────────────────────────────────────────────────────────────────────────────

# CONFIG
spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
timeout_secs=300 # = 5 minutes

#───────────────────────────────────────────────────────────────────────────────

current_repo=$(git remote --verbose | head -n1 | cut -d: -f2 | cut -d" " -f1)
for ((i = 1; i <= timeout_secs; i++)); do
	sleep 0.9 # assuming ~0.1 seconds per curl request
	last_run=$(
		curl --silent -L \
			-H "Accept: application/vnd.github+json" \
			-H "Authorization: Bearer $GITHUB_TOKEN" \
			-H "X-GitHub-Api-Version: 2022-11-28" \
			"https://api.github.com/repos/$current_repo/actions/runs?per_page=1"
	)
	run_status=$(echo "$last_run" | grep '"status":' | cut -d'"' -f4)

	# workflow name needs only to be fetched once, since it stays the same
	[[ $i -eq 1 ]] && workflow_name=$(echo "$last_run" | grep '"display_title":' | cut -d'"' -f4)

	[[ "$run_status" == "completed" ]] && break
	pos=$((i % ${#spinner}))
	printf "\33[2K\r" # fully delete previous line
	echo -n "${spinner:$pos:1} [$workflow_name] $run_status"
done
printf "\33[2K\r" # remove progress-message/spinner

#───────────────────────────────────────────────────────────────────────────────

if [[ "$run_status" != "completed" ]]; then
	msg="⚠️ Timeout after $timeout_secs seconds."
	sound="Basso"
	code=1
else
	conclusion=$(echo "$last_run" | grep '"conclusion":' | cut -d'"' -f4)
	if [[ "$conclusion" != "success" ]]; then
		msg="❌ $conclusion"
		sound="Basso"
		code=1
	else
		msg="✅ Success"
		sound="Hero"
		code=0
	fi
fi

echo "$msg"
[[ "$OSTYPE" =~ "darwin" ]] && afplay "/System/Library/Sounds/$sound.aiff" &
exit $code
