#!/bin/bash

SOURCE=$1
TARGET=.


make_multilib_paths () {
	LIB32_PATH=$1
	LIB64_PATH="$( sed 's@/lib/@/lib64/@g;' <(echo ${LIB32_PATH}) )"
	echo "${LIB32_PATH} ${LIB64_PATH}"
}


#
# wifi and gsm firmware's
#
FIRMWARE="/etc/firmware/"

#
# wmt_loader init kernel device modules, then waits for autokd. after autokd finishes its work,
# wmt_loader inits /dev/stpwmt, then 6620_launcher proceeds to load a firmware to the CPU using /dev/stpwmt.
#
WIFI="/etc/wifi/ /bin/6620_wmt_lpbk /bin/6620_launcher /bin/6620_wmt_concurrency /bin/wmt_loader \
/bin/autokd \
"

BLUETOOTH32="\
/lib/libbluetoothdrv.so /lib/libbluetooth_mtk.so \
/lib/libbtcusttable.so \
/lib/libbtstd.so \
/lib/libextsys.so /lib/libextsys_jni.so \
/lib/libbluetoothem_mtk.so /lib/libbluetooth_relayer.so \
/lib/libbtem.so \
"
BLUETOOTH="\
/bin/mtkbt \
/lib/libadpcm.so /lib/libbtcust.so /lib/libbtcusttc1.so \
/lib/libbtsession.so /lib/libbtpcm.so /lib/libbtsniff.so \
/lib/libpalsecurity.so /lib/libpalwlan_mtk.so \
/lib/libsbccodec.so \
$(make_multilib_paths "${BLUETOOTH32}")
"

# 
# gralloc && hwcomposer - hardware layer. rest is userspace lib.so layer.
#
# NOTE: /bin/program_binary_service is unusable because of lack of open-source
# framework-level counterparts, hence not included.
GL32="\
/lib/egl/libGLES_mali.so \
/lib/libm4u.so /lib/hw/gralloc.mt6735.so /lib/hw/hwcomposer.mt6735.so /lib/libbwc.so /lib/libgpu_aux.so \
/lib/libgralloc_extra.so /lib/libdpframework.so /lib/libion.so /lib/libion_mtk.so /lib/libged.so \
/lib/libaed.so /lib/libmtk_drvb.so /lib/libpq_prot.so /lib/libgui_ext.so /lib/libui_ext.so \
/lib/libvcodecdrv.so /lib/libvcodec_utility.so \
lib/libvc1dec_sa.ca7.so lib/libvp8dec_sa.ca7.so lib/libvp8enc_sa.ca7.so \
lib/libvp9dec_sa.ca7.so \
/lib/libperfservice.so /lib/libperfservicenative.so \
"
GL="\
/bin/guiext-server /bin/pq \
/lib/libvcodec_oal.so \
$(make_multilib_paths "${GL32}")
"

# Digital Restrictions Management
DRM32="/vendor/lib/mediadrm/libdrmclearkeyplugin.so /vendor/lib/mediadrm/libmockdrmcryptoplugin.so \
/lib/libdrmmtkutil.so /lib/libdrmmtkwhitelist.so \
/lib/libnvramagentclient.so \
"
DRM="\
/vendor/lib/libwvm.so /vendor/lib/libwvdrm_L3.so /vendor/lib/libWVStreamControlAPI_L3.so \
/vendor/lib/drm/libdrmwvmplugin.so \
/vendor/lib/mediadrm/libwvdrmengine.so \
/lib/drm/libdrmctaplugin.so /lib/drm/libdrmmtkplugin.so \
$(make_multilib_paths "${DRM32}")
"

# Codecs
CODECS32="/lib/libstagefrighthw.so \
/lib/libMtkOmxAdpcmDec.so /lib/libMtkOmxAdpcmEnc.so /lib/libMtkOmxAlacDec.so \
/lib/libMtkOmxApeDec.so /lib/libMtkOmxG711Dec.so /lib/libMtkOmxGsmDec.so \
/lib/libMtkOmxMp3Dec.so /lib/libMtkOmxRawDec.so /lib/libMtkOmxVorbisEnc.so \
/lib/libmhalImageCodec.so /lib/libmmprofile.so \
/lib/libJpgDecPipe.so /lib/libGdmaScalerPipe.so /lib/libSwJpgCodec.so /lib/libJpgEncPipe.so /lib/libmtkjpeg.so \
/lib/libBnMtkCodec.so \
"
# /lib/libstagefright_amrnb_common.so /lib/libstagefright_avc_common.so /lib/libstagefright_enc_common.so
CODECS="\
/etc/mtk_omx_core.cfg \
/bin/MtkCodecService \
/lib/libMtkOmxCore.so /lib/libmtb.so \
/lib/libMtkOmxFlacDec.so /lib/libMtkOmxVdec.so /lib/libMtkOmxVenc.so \
$(make_multilib_paths "${CODECS32}")
"

#
# ccci_mdinit starts, depends on additional services:
# - drvbd - unix socket connection - no longer exists on Lollipop+
# - nvram - folders /data/nvram, modem settings like IMEI
# - gsm0710muxd - /dev/radio/ ports for accessing the modem 
# - mdlogger
# - ccci_fsd
#
# ccci_mdinit loads modem_1_wg_n.img firmware to the CPU, waits for NVRAM to init using ENV variable.
# then starts the modem CPU. on success starts rest services mdlogger, gsm0710muxd ...
#
# ccci_fsd periodically says "Waiting permission check ready!", checking for a file called
# /data/nvram/md_new_ver.1 which obviously doesn't exist. Upon grepping this string a binary
# called permission_check popped out...
#
RIL32="/lib/mtk-ril.so /lib/mtk-rilmd2.so /lib/librilmtk.so /lib/librilmtkmd2.so \
/lib/libnvram.so /lib/libcustom_nvram.so /lib/libnvram_sec.so \
/lib/libhwm.so /lib/libnvram_platform.so /lib/libfile_op.so /lib/libnvram_daemon_callback.so \
/lib/libmdloggerrecycle.so \
/lib/libatciserv_jni.so /lib/libaal.so \
/lib/libccci_util.so \
"
CDMA32="\
/lib/libc2kutils.so \
"
CDMA="\
/bin/statusd /bin/flashlessd /bin/viaradiooptions /bin/viarild /bin/pppd_via \
/lib/libc2kril.so /lib/libviatelecom-withuim-ril.so \
$(make_multilib_paths "${CDMA32}")
"
RIL="\
/bin/nvram_daemon /bin/nvram_agent_binder /bin/aee \
/bin/gsm0710muxd /bin/gsm0710muxdmd2 /bin/ccci_fsd /bin/ccci_mdinit \
/bin/atci_service /bin/atcid /bin/audiocmdservice_atci /bin/permission_check \
/bin/md_ctrl /bin/muxreport /bin/mtkrild /bin/mtkrildmd2 \
/bin/terservice /lib64/libterservice.so \
/lib/libexttestmode.so \
/xbin/BGW \
$(make_multilib_paths "${RIL32}") \
${CDMA}
"

# fxxk, audio depends on c2k ril on this model
AUDIO32="\
/lib/hw/audio.primary.mt6735.so \
/lib/libblisrc.so /lib/libblisrc32.so /lib/libspeech_enh_lib.so /lib/libaudiocustparam.so /lib/libaudiosetting.so \
/lib/libaudiocompensationfilter.so /lib/libcvsd_mtk.so /lib/libmsbc_mtk.so /lib/libaudiocomponentengine.so \
/lib/libbessound_hd_mtk.so /lib/libmtklimiter.so /lib/libmtkshifter.so /lib/libaudiodcrflt.so \
/lib/libspeech_enh_lib.so \
/lib/libtinyalsa.so /lib/libtinyxml.so \
"
AUDIO="\
/etc/audio_device.xml \
$(make_multilib_paths "${AUDIO32}")
"

CAMERA32="/lib/hw/camera.mt6735.so /lib/libcam_platform.so \
/lib/lib3a.so /lib/lib3a_sample.so /lib/libSonyIMX230PdafLibrary.so \
/lib/libcam.camadapter.so /lib/libcam.camnode.so /lib/libcam.camshot.so \
/lib/libcam.client.so /lib/libcam.device1.so /lib/libcam.device3.so \
/lib/libcam.exif.so /lib/libcam.exif.v3.so /lib/libcam.hal3a.v3.dng.so \
/lib/libcam.hal3a.v3.so /lib/libcam.halsensor.so /lib/libcam.iopipe.so \
/lib/libcam.metadata.so /lib/libcam.metadataprovider.so \
/lib/libcam.paramsmgr.so /lib/libcam.sdkclient.so \
/lib/libcam.utils.cpuctrl.so /lib/libcam.utils.sensorlistener.so \
/lib/libcam.utils.so /lib/libcam1_utils.so /lib/libcam3_app.so \
/lib/libcam3_hwnode.so /lib/libcam3_hwpipeline.so /lib/libcam3_pipeline.so \
/lib/libcam3_utils.so /lib/libcam_hwutils.so /lib/libcam_mmp.so \
/lib/libcam_utils.so /lib/libcamalgo.so /lib/libcamdrv.so \
/lib/libcamera_client_mtk.so /lib/libcameracustom.so /lib/libdngop.so \
/lib/libfeatureio.so /lib/libfeatureiodrv.so /lib/libimageio.so \
/lib/libimageio_plat_drv.so /lib/libmatv_cust.so \
/lib/libmmsdkservice.feature.so /lib/libmmsdkservice.so /lib/libmpo.so \
/lib/libmpoencoder.so /lib/libmtk_mmutils.so /lib/libn3d3a.so \
/lib/libts_face_beautify_hal.so \
"
CAMERA="\
$(make_multilib_paths "${CAMERA32}")
"

SENSORS32="/lib/hw/sensors.mt6735.so \
"
SENSORS="\
/bin/akmd8963 /bin/akmd8975 /bin/akmd09911 /bin/ami304d /bin/bmm050d \
/bin/mc6420d /bin/memsicd /bin/memsicd3416x /bin/msensord /bin/s62xd \
/bin/geomagneticd /bin/magd /bin/orientationd \
$(make_multilib_paths "${SENSORS32}")
"

GPS32="\
/lib/hw/gps.default.so \
"
GPS="\
/bin/mtk_agpsd /bin/wifi2agps /xbin/mnld \
/lib/libmnl.so \
$(make_multilib_paths "${GPS32}")
"

CHARGER="/bin/kpoc_charger /lib/libshowlogo.so /lib/libsuspend.so"

MISC="/bin/thermal /bin/thermald /bin/thermal_manager \
/bin/ppl_agent /bin/matv \
"

SYSTEM="$FIRMWARE $WIFI $BLUETOOTH $GL $DRM $CODECS $RIL $AUDIO $CAMERA $SENSORS $GPS $CHARGER $MISC"

rename_file () {
	local src
	local dest

	if [[ "x$1" == "x-b" ]]; then
		src=$3
		dest=$2
	else
		src=$1
		dest=$2
	fi

	mv $TARGET/$src $TARGET/$dest
}

move_files () {
	# unneeded as of Lollipop
	#rename_file $1 lib/hw/audio.primary.mt6735.so lib/libaudio.primary.default.so
	#rename_file $1 vendor/lib/hw/audio.a2dp.blueangel.so vendor/lib/hw/audio.a2dp.mt6735.so
	true
}

# get data from a device
if [ -z $SOURCE ]; then
  for FILE in $SYSTEM ; do
    T=$TARGET/$FILE
    adb pull /system/$FILE $T
  done
  move_files
  exit 0
fi

# get data from folder
move_files -b
for FILE in $SYSTEM ; do
  S=$SOURCE/$FILE
  T=$TARGET/$FILE
  mkdir -p $(dirname $T) || exit 1
  rsync -av --delete $S $T || exit 1
done
move_files
exit 0

