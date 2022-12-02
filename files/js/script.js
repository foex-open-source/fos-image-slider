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
 * @param {boolean}       [config.watchSlidesProgress]   Enable this feature to calculate each slides progress and visibility (slides in viewport will have additional visible class). Default true.
 * @param {number}        [config.speed]                 Duration of transition between slides (in ms). Default 300ms.
 * @param {number}        [config.spaceBetween]          Distance between slides in px.
 * @param {object}        [config.breakpoints]           Allows to set different parameter for different responsive breakpoints (screen sizes).
 * @param {function}      [initFn]                       Javascript initialization function which allows you to override any settings before the slider is created.
 */



FOS.region.imageSlider.initSlider = function(config, initJs) {
    apex.debug.info('FOS - Image Slider: ', config);

    // default values
    config.watchSlidesProgress = true;
    config.speed = 300;
    config.spaceBetween = 0;
    config.breakPoints = {};

    // execute the initJs function
    if (initJs && typeof initJs == 'function') {
        initJs.call(this, config);
    }

    const CSS_PREFIX = 'fos-image-slider';
    const ICON_FULLSCREEN_IS_ON = 'fa-compress';
    const ICON_FULLSCREEN_IS_OFF = 'fa-expand';

    const SLIDE_CHANGE_EVENT = 'fos-imageslider-slide-change';
    const FULLSCREEN_ENTER_EVENT = 'fos-imageslider-fullscreen-enter';
    const FULLSCREEN_EXIT_EVENT = 'fos-imageslider-fullscreen-exit';
    const SLIDE_CLICK_EVENT = 'fos-imageslider-slide-click';

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
        imageSizeCustom,
        pluginUri,
        pageItemsToSubmit
    } = config;
    let swiperCfg = {
        observer: true,
        observeSlideChildren: true,
        keyboard: {
            enabled: true,
            onlyInViewport: true
        },
        lazy: {
            loadPrevNext: true,
            checkInView: true
        },
        loop,
        slidesPerView: parseInt(imagesPerRegion) || 1,
        effect: transition == 'slide' ? false : transition,
        direction,
        initialSlide: 0
    };
    let regionStyle = '';

    pageItemsToSubmit = pageItemsToSubmit ? pageItemsToSubmit : '';

    if (width) {
        regionStyle += 'width:' + (typeof width == 'number' ? `${width}px` : width) + ';';
    }
    if (height) {
        regionStyle += 'height:' + (typeof height == 'number' ? `${height}px` : height) + ';';
    }

    regionEl.setAttribute('style', regionStyle);

    if (autoplay) {
        swiperCfg.autoplay = {
            delay: parseFloat(delaySecs) * 1000,
            disableOnInteraction: false,
            pauseOnMouseEnter: true
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
            observer: true,
            observeSlideChildren: true,
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

    if(swiperCfg.slidesPerView > 1){
        swiperCfg.speed = config.speed;
        swiperCfg.spaceBetween = config.spaceBetween;
        swiperCfg.watchSlidesProgress = config.watchSlidesProgress;
        swiperCfg.breakpoints = config.breakPoints;
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

    swiper.on('click', (swiper,event)=> {
        triggerEvent(SLIDE_CLICK_EVENT,event.target);
    })

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

    function refreshSliderUrl() {
        apex.message.clearErrors();

        // always remove all the current slides
        swiper.removeAllSlides();
        thumbsSwiper.removeAllSlides();

        apex.server.plugin(
            pluginUri,
            {
                //x01 reserved for PK
                x02: 'BLOB_URLS',
                pageItems: pageItemsToSubmit.split(',')
                            .map(id => id.trim())
                            .map(id => `#${id}`)
                            .join(',')
            },
            {
                dataType: 'json',
                success: function(jsonData){                    
                    if (apex.debug.getLevel() != apex.debug.LOG_LEVEL.OFF) {
                        apex.debug.info(`${CSS_PREFIX} jsonData: ${jsonData}`);                        
                    }
                    
                    for (let i = 0; i < jsonData.result.length; i++) {
                        const element = jsonData.result[i];
                        swiper.addSlide(i,
                            `
                                <div class="swiper-slide swiper-lazy" data-background="${element}">
                                <div class="swiper-lazy-preloader"></div>
                            `
                        );

                        thumbsSwiper.addSlide(i,
                            `
                                <div class="swiper-slide ${CSS_PREFIX}-thumbnail-slide" 
                                    style="background-image:url(${element})">
                                </div>
                            `
                        );
                    }

                    swiper.update();
                    thumbsSwiper.update();

                    // set the custom sizes here after initialization as some slides may have been duplicated (when loop mode)
                    sliderContainerEl.querySelectorAll(`.${CSS_PREFIX}-gallery .swiper-slide`).forEach(el => {
                        el.style.backgroundSize = imageSize == 'custom' ? imageSizeCustom + '%' : imageSize;
                    });
                },
                error: function(xhr, ajaxOptions, thrownError){

                    if (apex.debug.getLevel() != apex.debug.LOG_LEVEL.OFF) {
                        apex.debug.error(`${CSS_PREFIX} ajaxOptions: ${ajaxOptions}`);
                        apex.debug.error(`${CSS_PREFIX} thrownError: ${thrownError}`);
                    }

                    apex.message.showErrors([
                        {
                            type:       'error',
                            location:   'page',                            
                            message:    xhr.responseText,
                            unsafe:     false
                        }                        
                    ]);

                    swiper.update();
                    thumbsSwiper.update();
                }
            }
        );
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
        },

        stopAutoplay(){
            if(swiper.autoplay){
                swiper.autoplay.stop();
            }
        },

        isAutoplayRunning(){
            return swiper.autoplay.running;
        },

        startAutoplay(){
            if(swiper.autoplay){
                swiper.autoplay.start();
            }
        },

        refresh(){
            //if (pluginUri){
                refreshSliderUrl();            
            //}
        }        

    });
}

