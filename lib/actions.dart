library actions;

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ActionResult<T> {
  final Function invoke;
  final AsyncSnapshot<T> result;
  final Function reset;

  ActionResult._(this.invoke, this.result, this.reset);
}

ActionResult<T> useAction<T>(
  Future<T> Function() block,
  List<Object?> keys, {
  bool runOnStart = false,
}) {
  final mounted = useIsMounted();
  final current = useState(const AsyncSnapshot<T>.waiting());

  final reset = useCallback(
    () {
      if (mounted()) {
        current.value = const AsyncSnapshot.waiting();
      }
    },
    [mounted],
  );

  final invokeCommand = useAsyncCallbackDedup(
    () async {
      try {
        if (mounted()) current.value = const AsyncSnapshot.waiting();
        final ret = await block();
        if (mounted()) {
          current.value = AsyncSnapshot.withData(ConnectionState.done, ret);
        }

        return ret;
      } catch (e) {
        if (mounted()) {
          current.value = AsyncSnapshot.withError(ConnectionState.done, e);
        }
        throw e;
      }
    },
    keys,
  );

  useFutureEffect(
    () async {
      if (runOnStart) {
        await invokeCommand();
      }
      // eslint-disable-next-line react-hooks/exhaustive-deps
    },
    [
      invokeCommand,
    ],
  );

  return useMemoized(
    () => ActionResult._(invokeCommand, current.value, reset),
    [invokeCommand, current.value, reset],
  );
}

  const [ret, setRet] = useState(Result.pending<T>())
  const mounted = useMounted()

  useEffect(() => {
    let d = Subscription.EMPTY
    let set = false,
      done = false
    if (!mounted.current) {
      return () => {}
    }

    try {
      d = block().subscribe({
        next: (x) => {
          set = true
          if (mounted.current) setRet(Result.ok(x))
        },
        error: (e) => {
          set = true
          done = true
          if (mounted.current) {
            setRet(Result.err(e))
          }
        },
        complete: () => {
          done = true
          Promise.resolve().then(() => {
            if (ret.isPending() && !set) {
              setRet(
                Result.err(
                  new Error('Observable must have at least one element')
                )
              )
            }
          })
        },
      })
    } catch (e: any) {
      setRet(Result.err(e))
    }

    return () => d.unsubscribe()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)

  return ret


AsyncSnapshot<T> useStreamEffect<T>(
  Stream<T> Function() block,
  List<Object?> keys,
) {
  final ret = useState(AsyncSnapshot<T>.waiting());
  final mounted = useIsMounted();

  useEffect(() => {
    let d = Subscription.EMPTY
    let set = false,
      done = false
    if (!mounted.current) {
      return () => {}
    }

    try {
      d = block().subscribe({
        next: (x) => {
          set = true
          if (mounted.current) setRet(Result.ok(x))
        },
        error: (e) => {
          set = true
          done = true
          if (mounted.current) {
            setRet(Result.err(e))
          }
        },
        complete: () => {
          done = true
          Promise.resolve().then(() => {
            if (ret.isPending() && !set) {
              setRet(
                Result.err(
                  new Error('Observable must have at least one element')
                )
              )
            }
          })
        },
      })
    } catch (e: any) {
      setRet(Result.err(e))
    }

    return () => d.unsubscribe()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)

  return ret
}

AsyncSnapshot<T> useFutureEffect<T>(
  Future<T> Function() block,
  List<Object?> keys,
) {}

Future<T?> Function() useAsyncCallbackDedup<T>(
  Future<T> Function() block,
  List<Object?> keys,
) {
  final cur = useRef<Future<T>?>(null);

  final cb = useCallback(
    () {
      if (cur.value != null) {
        return Future<T?>.value();
      }

      cur.value = block();
      return cur.value!.whenComplete(() => cur.value = null);
    },
    keys,
  );

  return cb;
}

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;

  build() {}
}
