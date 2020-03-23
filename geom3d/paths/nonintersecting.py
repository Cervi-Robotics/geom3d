import logging
import typing as tp

logger = logging.getLogger(__name__)


def make_nonintersecting(paths: tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]:
    """
    Make the paths non-intersecting.

    This will be done by adjusting their z-value
    :param paths:
    :return:
    """