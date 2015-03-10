# A very minimal ceph install script, using ceph-deploy
set -x

RELEASE=${1:firefly}
# Creating a directory based on timestamp..not unique enough
mkdir -p ~/ceph-deploy/install-$(date +%Y%m%d%H%M%S) && cd $_
wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -

sudo apt-add-repository `deb http://ceph.com/debian-firefly/ $RELEASE main`

sudo apt-get update && sudo apt-get install -y ceph-deploy


ceph-remove () {
ceph-deploy purge $HOST
ceph-deploy purgedata $HOST
ceph-deploy forgetkeys

for i in 0 1 2
do
    [ -d /var/local/osd$i ] && sudo rm -rf /var/local/osd$i
done
[ -f /etc/ceph/ceph.conf ] && sudo rm -rf /etc/ceph/ceph.conf
}

HOST=$(hostname -s)
FQDN=$(hostname -f)
ceph-remove
ceph-deploy new $HOST

cat <<EOF >> ceph.conf
osd pool default size=2
osd crush chooseleaf type = 0
EOF

ceph-deploy install $HOST --release $RELEASE
ceph-deploy mon create-initial $HOST

sudo mkdir /var/local/osd0
sudo mkdir /var/local/osd1
sudo mkdir /var/local/osd2

ceph-deploy osd prepare $HOST:/var/local/osd0 $HOST:/var/local/osd1 $HOST:/var/local/osd2
ceph-deploy osd activate  $HOST:/var/local/osd0 $HOST:/var/local/osd1 $HOST:/var/local/osd2
sleep 30 # Give some time for ceph to work its magic
sudo ceph health

