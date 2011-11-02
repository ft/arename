#!/bin/sh

files="arename.in
ataglist.in
ARename.pm.in
$(find modules/ARename -name \*.pm.in)"

sh ./bin/critic.sh ${files}
