import fanBeautyMask from './preview-images/FanBeautyMask.webp';
import chanelCleanser from './preview-images/ChanelCleanser.webp';
import skinCeuticalsCream from './preview-images/SkinCeuticalsCream.webp';
import cleDePeauPrimer from './preview-images/CleDePeauPrimer.webp';
import yslFoundation from './preview-images/YSLFoundation.webp';
import givenchyLoosePowder from './preview-images/GivenchyLoosePowder.webp';
import narsPressedPowder from './preview-images/NARSPressedPowder.webp';
import chanelBlush from './preview-images/ChanelBlush.webp';
import maoGepingPalette from './preview-images/MaoGepingPalette.webp';
import chanelLipstick from './preview-images/ChanelLipstick.webp';
import momoWorkshopPuff from './preview-images/MomoWorkshopPuff.webp';

/** 分类定义：顺序与 iOS 版一致，照片用作分类封面。 */
export const categories = [
  { id: 'mask', title: '面膜', src: fanBeautyMask, alt: 'Fan Beauty Diary 面膜' },
  { id: 'cleanser', title: '洁面乳', src: chanelCleanser, alt: '香奈儿洁面乳' },
  { id: 'cream', title: '面霜', src: skinCeuticalsCream, alt: '修丽可面霜' },
  { id: 'primer', title: '隔离', src: cleDePeauPrimer, alt: '肌肤之钥隔离' },
  { id: 'foundation', title: '粉底液', src: yslFoundation, alt: 'YSL 粉底液' },
  { id: 'loose-powder', title: '散粉', src: givenchyLoosePowder, alt: '纪梵希四宫格散粉' },
  { id: 'pressed-powder', title: '蜜粉饼', src: narsPressedPowder, alt: 'NARS 蜜粉饼' },
  { id: 'blush', title: '腮红', src: chanelBlush, alt: '香奈儿腮红' },
  { id: 'eyeshadow', title: '眼影盘', src: maoGepingPalette, alt: '毛戈平眼影盘' },
  { id: 'lipstick', title: '口红', src: chanelLipstick, alt: '香奈儿口红' },
  { id: 'puff', title: '粉扑', src: momoWorkshopPuff, alt: '粉扑' }
];

export const categoryById = id => categories.find(item => item.id === id);
