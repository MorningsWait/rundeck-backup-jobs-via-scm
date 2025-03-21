echo "################################ Working on <rundeck> ######################################"
export RD_URL="http://<your Rundeck url>:4440/api/46"
export RD_TOKEN="<Rundeck API Token>"

RD_OPTION_PROJECTS=""
PROJECT=""
RD_OPTION_PROJECTS="$(rd projects list | awk NF | tail -n +2)"
for PROJECT in $RD_OPTION_PROJECTS; do
    echo "***Working for Project: $PROJECT"
#    rd projects scm perform -AMTU -a "project-commit" -i export --field message="daily Sync on $(date '+%Y-%m-%d') by Automation ran on $HOSTNAME" -p $PROJECT
#    read -p "Pause Time 60 seconds" -t 60
    STATUS=`rd projects scm status --project $PROJECT --integration export`

    echo "Current status for $PROJECT:"
    echo "$STATUS"
    echo ""

    SYNCH_STATE=`echo "$STATUS" | grep synchState | sed "s/synchState: \(.*\)$/\1/"`

    if [ "$SYNCH_STATE" == "EXPORT_NEEDED" ]; then
        echo "Because synchState is $SYNCH_STATE, we must commit/push to the remote repo"

        ACTION=`echo "$STATUS" | grep -A 1 actions | tail -n 1 | awk '{$1=$1};1'`
        JOB_IDS=`rd jobs list --project $PROJECT --outformat "%id" | head -n -1 | xargs echo`

        echo "Performing a '$ACTION'... on $PROJECT"
        rd projects scm perform --project $PROJECT \
            --integration export \
            --action $ACTION \
            --job $JOB_IDS \
            --field message="Daily sync on $(date '+%Y-%m-%d') by Automation ran on $HOSTNAME"

        echo "Performing a 'project-push'... on $PROJECT"
        rd projects scm perform --project $PROJECT --integration export --action project-push
    else
        echo "Skipping : seems no changes found for any Job !!"
    fi
done
