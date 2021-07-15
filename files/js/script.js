/* globals apex,$ */
window.FOS = window.FOS || {};
FOS.region = FOS.region || {};
FOS.region.imageSlider = FOS.region.imageSlider || {};

/**
 * Initialization function for the image slider region.
 *
 * @param {object}        config                         The object holding the slider's configuration.
 * @param {string}        config.regionId                The dom id of the region.
 * @param {number|string} config.width                   The width of the slider.
 * @param {number|string} config.height                  The height of the slider.
 * @param {string}        [config.transition]            The transition/animation of the slide changes, defaults to 'slide'.
 * @param {boolean}       [config.autoplay]              Sets whether the slides should change automatically after a set period of time.
 * @param {number}        [config.delaySecs]             The number of seconds each slide should be displayed while autoplaying.
 * @param {number}        [config.imagesPerRegion]       The number of images displayed per slide (i.e. fitting into the view of the region at once).
 * @param {boolean}       [config.pagination]            Displays clickable bullets at the bottom of the slider, one for each slide.
 * @param {boolean}       [config.hidePaginationOnClick] Hides/shows the pagination when a slide is clicked.
 * @param {boolean}       [config.navigation]            Displays navigation buttons to change the slides.
 * @param {boolean}       [config.hideNavigationOnClick] Hides/shows the navigation when a slide is clicked.
 * @param {boolean}       [config.thumbnailsEnabled]     Enables thumbnails.
 * @param {boolean}       [config.fullscreenSupport]     Enables fullscreen support.
 * @param {boolean}       [config.loop]                  Enables looping of the slides (i.e. after the last slide the first one transitions in and vice-versa).
 * @param {string}        [config.direction]             The direction of the slide changes, either horizontal (default) or vertical.
 * @param {string}        [config.imageSize]             Sets how the images should fit into the slides, whether they should stretch (cover - default), fit (contain) or should be scaled (custom).
 * @param {number}        [config.imageSizeCustom]       If the images are scaled, this is the scale percentage.
 * @param {function}      [initFn]                       Javascript initialization function which allows you to override any settings before the slider is created.
 */

FOS.region.imageSlider.initSlider = function(config, initJs) {
    // execute the initJs function
    if (initJs && typeof initJs == 'function') {
        initJs.call(this, config);
    }
    console.log(config);

    const CSS_PREFIX = 'fos-image-slider';
    const ICON_FULLSCREEN_IS_ON = 'fa-compress';
    const ICON_FULLSCREEN_IS_OFF = 'fa-expand';

    const SLIDE_CHANGE_EVENT = 'fos-imageslider-slide-change';
    const FULLSCREEN_ENTER_EVENT = 'fos-imageslider-fullscreen-enter';
    const FULLSCREEN_EXIT_EVENT = 'fos-imageslider-fullscreen-exit';

    let regionId = config.regionId;
    let regionEl = document.querySelector(`#${regionId}`);
    let sliderContainerEl = regionEl.querySelector(`.${CSS_PREFIX}-container`);
    let fullscreenBtn;
    let swiper;
    let thumbsSwiper;
    let {
        width = 800,
        height = 500,
        autoplay,
        delaySecs,
        imagesPerRegion = 1,
        pagination,
        hidePaginationOnClick,
        navigation,
        hideNavigationOnClick,
        thumbnailsEnabled,
        fullscreenSupport,
        thumbnails = 5,
        loop,
        transition = 'slide',
        direction = 'horizontal',
        imageSize = 'cover',
        imageSizeCustom
    } = config;
    let swiperCfg = {
        keyboard: {
            enabled: true,
            onlyInViewport: true
        },
        lazy: {
            loadPrevNext: true
        },
        loop,
        slidesPerView: parseInt(imagesPerRegion) || 1,
        effect: transition == 'slide' ? false : transition,
        direction,
        initialSlide: 0
    };
    let regionStyle = '';

    if (width) {
        regionStyle += 'width:' + (typeof width == 'number' ? `${width}px;` : width);
    }
    if (height) {
        regionStyle += 'height:' + (typeof height == 'number' ? `${height}px;` : height);
    }
    regionEl.setAttribute('style', regionStyle);

    if (autoplay) {
        swiperCfg.autoplay = {
            delay: parseFloat(delaySecs) * 1000,
            disableOnInteraction: false
        };
    }

    if (pagination) {
        swiperCfg.pagination = {
            el: sliderContainerEl.querySelector('.swiper-pagination'),
            clickable: true,
            hideOnClick: hidePaginationOnClick
        };
    }

    if (navigation) {
        swiperCfg.navigation = {
            nextEl: sliderContainerEl.querySelector('.swiper-button-next'),
            prevEl: sliderContainerEl.querySelector('.swiper-button-prev'),
            hideOnClick: hideNavigationOnClick
        }
    }

    if (fullscreenSupport) {
        fullscreenBtn = sliderContainerEl.querySelector(`.${CSS_PREFIX}-fullscreen-btn`);
        sliderContainerEl.addEventListener('fullscreenchange', fullscreenHandler);
        fullscreenBtn.addEventListener('click', fullscreenBtnClickHandler);
    }

    if (thumbnailsEnabled) {
        let thumbsEl = sliderContainerEl.querySelector(`.${CSS_PREFIX}-thumbnails`);
        thumbsSwiper = new Swiper(thumbsEl, {
            spaceBetween: 6,
            slidesPerView: thumbnails == 0 ? 'auto' : parseInt(thumbnails),
            watchSlidesVisibility: true,
            watchSlidesProgress: true,
            autoplay: false,
            loop: false,
        });
        swiperCfg.thumbs = {
            swiper: thumbsSwiper
        }
    }

    swiper = new Swiper(sliderContainerEl.querySelector(`.${CSS_PREFIX}-gallery`), swiperCfg);

    // set the custom sizes here after initialization as some slides may have been duplicated (when loop mode)
    sliderContainerEl.querySelectorAll(`.${CSS_PREFIX}-gallery .swiper-slide`).forEach(el => {
        el.style.backgroundSize = imageSize == 'custom' ? imageSizeCustom + '%' : imageSize;
    });

    swiper.on('slideChange', _ => {
        let index = swiper.activeIndex;
        triggerEvent(SLIDE_CHANGE_EVENT, { index, swiper });
    });

    function fullscreenBtnClickHandler(e) {
        if (!document.fullscreenElement) {
            sliderContainerEl.requestFullscreen()
                .catch(err => {
                    console.warn(`Error attempting to enable full-screen mode: ${err.message} (${err.name})`);
                });
        }
        else {
            document.exitFullscreen();
        }
    }

    function fullscreenHandler(e) {
        let cl = fullscreenBtn.firstElementChild.classList;
        if (document.fullscreenElement) {
            cl.remove(ICON_FULLSCREEN_IS_OFF);
            cl.add(ICON_FULLSCREEN_IS_ON);
            triggerEvent(FULLSCREEN_ENTER_EVENT, { swiper });
        }
        else {
            cl.remove(ICON_FULLSCREEN_IS_ON);
            cl.add(ICON_FULLSCREEN_IS_OFF);
            triggerEvent(FULLSCREEN_EXIT_EVENT, { swiper });
        }
    }

    function triggerEvent(eventName, paramsObj) {
        apex.event.trigger(`#${regionId}`, eventName, paramsObj);
    }

    // plugin's public interface
    apex.region.create(regionId, {
        slideNext(speed = 300, runCallbacks = true) {
            swiper.slideNext(speed, runCallbacks);
        },

        slidePrev(speed = 300, runCallbacks = true) {
            swiper.slidePrev(speed, runCallbacks);
        },

        slideTo(index, speed = 300, runCallbacks = true) {
            swiper.slideTo(index, speed, runCallbacks)
        },

        getGallerySlider() {
            return swiper;
        },

        getThumbnailsSlider() {
            return thumbsSwiper;
        }
    });
}

