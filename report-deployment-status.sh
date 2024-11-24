#!/usr/bin/env zsh
# INFO
# - Checks the deployment status of the latest GitHub Action run and exits either
#   after a timeout or when done.
# - Requires the `$GITHUB_TOKEN`.
# - The json response from GitHub is parsed via `cut` and `grep` instead of
#   `jq`/`yq` to avoid introducing a dependency.
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
	printf "\r[%s] %s %s" "$workflow_name" "${spinner:$pos:1}" "$run_status"
done
printf "\r" # remove progress-message/spinner

conclusion=$(echo "$last_run" | grep '"conclusion":' | cut -d'"' -f4)
if [[ "$run_status" != "completed" ]]; then
	echo "⚠️ Timeout after $timeout_secs seconds."
elif [[ "$conclusion" != "success" ]]; then
	echo "❌ $conclusion"
else
	echo "✅ Success"
fi